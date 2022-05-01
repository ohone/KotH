// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./IERC4626.sol";
import "./IKotH.sol";

/**
 * @title Council
 * @dev King of the hill game collaborative party.
 */
contract Council is IERC4626, ERC20 {
    address KotHAddress;
    uint256 winnings;

    constructor(address targetAddress) ERC20("name", "symbol") {
        KotHAddress = targetAddress;
    }

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     */
    function asset() external view returns (address assetTokenAddress) {
        return IKotH(KotHAddress).getTokenAddress();
    }

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets) {
        return
            IERC20(IKotH(KotHAddress).getTokenAddress()).balanceOf(
                address(this)
            );
    }

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets)
        external
        pure
        returns (uint256 shares)
    {
        return assets;
    }

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares)
        external
        pure
        returns (uint256 assets)
    {
        return shares;
    }

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address) external view returns (uint256 maxAssets) {
        // if the contract hasn't won, and isn't currently king
        if (!haveWon() && !isKing()) {
            IKotH target = IKotH(KotHAddress);

            // can deposit up to current IKotH limit + 1
            uint256 currnetLimit = target.getCurrentAmount() + 1;

            return
                currnetLimit -
                IERC20(target.getTokenAddress()).balanceOf(address(this));
        }

        // otherwise, contract is king (pending victory)
        // or already won, don't allow deposits
        return 0;
    }

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets)
        external
        pure
        returns (uint256 shares)
    {
        return assets;
    }

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver)
        external
        validDeposit(assets)
        returns (uint256 shares)
    {
        _mint(receiver, assets);
        // transfer toens to us
        IERC20(IKotH(KotHAddress).getTokenAddress()).transferFrom(
            msg.sender,
            address(this),
            assets
        );
        emit Deposit(msg.sender, receiver, assets, assets);
        return assets;
    }

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address) external view returns (uint256 maxShares) {
        // if the contract hasn't won, and isn't currently king
        if (!haveWon() && !isKing()) {
            IKotH target = IKotH(KotHAddress);

            // can deposit up to current IKotH limit + 1
            uint256 currnetLimit = target.getCurrentAmount() + 1;

            return
                currnetLimit -
                IERC20(target.getTokenAddress()).balanceOf(address(this));
        }

        // otherwise, contract is king (pending victory)
        // or already won, don't allow deposits
        return 0;
    }

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares)
        external
        pure
        returns (uint256 assets)
    {
        return shares;
    }

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver)
        external
        validDeposit(shares)
        returns (uint256 assets)
    {
        _mint(receiver, shares);
        // transfer toens to us
        IERC20(IKotH(KotHAddress).getTokenAddress()).transferFrom(
            msg.sender,
            address(this),
            shares
        );
        emit Deposit(msg.sender, receiver, shares, shares);
        return shares;
    }

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner)
        external
        view
        returns (uint256 maxAssets)
    {}

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets)
        external
        view
        returns (uint256 shares)
    {}

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares) {
        require(!isKing(), "withdrawals suspended, council is king");

        // if the concil is the winner,
        // calculate the number of tokens the withdrawer must have
        // to claim assets assets.
        if (haveWon()) {
            uint256 tokenRequirement = (assets * totalSupply()) /
                IERC20(IKotH(KotHAddress).getTokenAddress()).balanceOf(
                    address(this)
                );
            require(
                balanceOf(owner) >= tokenRequirement,
                "insufficient balance of tokens to withdraw asset amount"
            );

            _burn(owner, tokenRequirement);
            IERC20(IKotH(KotHAddress).getTokenAddress()).transfer(
                receiver,
                assets
            );
            emit Withdraw(msg.sender, receiver, owner, assets, assets);
            return tokenRequirement;
        }
        // otherwise, 1:1
        _burn(owner, assets);
        IERC20(IKotH(KotHAddress).getTokenAddress()).transfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, assets);
        return assets;
    }

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner)
        external
        view
        returns (uint256 maxShares)
    {
        if (!canRedeem()) {
            return 0;
        }

        return balanceOf(owner);
    }

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares)
        external
        view
        returns (uint256 assets)
    {
        return haveWon() ? shares * 2 : shares;
    }

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256) {
        require(!isKing(), "withdrawals suspended, council is king");
        require(balanceOf(owner) >= shares, "insufficient balance of shares");

        if (haveWon()) {
            uint256 finalShares = ((shares * winnings) / totalSupply());
            _burn(owner, shares);
            IERC20(IKotH(KotHAddress).getTokenAddress()).transfer(
                receiver,
                finalShares
            );
            emit Withdraw(msg.sender, receiver, owner, shares, shares);
            return shares;
        }

        _burn(owner, shares);
        IERC20(IKotH(KotHAddress).getTokenAddress()).transfer(receiver, shares);
        emit Withdraw(msg.sender, receiver, owner, shares, shares);
        return shares;
    }

    /**
     * @dev Claims victory on behalf of the council.
     */
    function claimVictory() external {
        require(canClaimVictory(), "havent won");
        winnings = IKotH(KotHAddress).claimVictory(address(this));
    }

    /**
     * @dev Whether the council can claim victory over the hill.
     */
    function canClaimVictory() public view returns (bool) {
        return
            IKotH(KotHAddress).getCurrentKing() == address(this) &&
            block.timestamp >= IKotH(KotHAddress).getExpires();
    }

    /**
     * @dev Whether the winnings have been claimed by the council.
     */
    function haveWon() public view returns (bool) {
        return winnings > 0;
    }

    /**
     * @dev Claims the hill on behalf of the council.
     * Will always claim with the minimum amount possible, which
     * should be all contributions to the contract.
     */
    function claimHill() external {
        IKotH target = IKotH(KotHAddress);
        uint256 amount = target.getCurrentAmount() + 1;
        IERC20(target.getTokenAddress()).approve(KotHAddress, amount);
        target.capture(amount);
    }

    modifier validDeposit(uint256 amount) {
        require(amount <= maxDeposit(), "deposit amount is bigger than max");
        _;
    }

    /**
     * @dev Whether a contributor can redeem his tokens from the council.
     */
    function canRedeem() public view returns (bool redeemable) {
        return !isKing();
    }

    /**
     * @dev The maximum deposit available.
     */
    function maxDeposit() public view returns (uint256 amount) {
        // if the contract hasn't won, and isn't currently king
        if (!haveWon() && !isKing()) {
            IKotH target = IKotH(KotHAddress);

            // can deposit up to current IKotH limit + 1
            uint256 currnetLimit = target.getCurrentAmount() + 1;

            return
                currnetLimit -
                IERC20(target.getTokenAddress()).balanceOf(address(this));
        }

        // otherwise, contract is king (pending victory)
        // or already won, don't allow deposits
        return 0;
    }

    /**
     * @dev Whether the council is currently KotH.
     */
    function isKing() public view returns (bool) {
        return IKotH(KotHAddress).getCurrentKing() == address(this);
    }
}

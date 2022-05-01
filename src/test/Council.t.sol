// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "ds-test/test.sol";
import "./Hevm.sol";
import "../Council.sol";
import "./TestToken.sol";
import "../KotH.sol";
import "../IKoth.sol" as KotHInterface;

contract CouncilTest is DSTest {
    Hevm vm = Hevm(HEVM_ADDRESS);
    IKotH CuT;
    TestToken token;
    Council council;
    uint256 reign;
    event Captured(address indexed king, uint256 indexed amount);

    function setUp() public {
        token = new TestToken();
        reign = 100;
        CuT = new KotH(address(token), reign);
        council = new Council(address(CuT));
        // default expiry for KotH is 0, must warp beyond this time
        // to fulfil capture requirement.
        vm.warp(1);
    }

    function test_NotKing_CanDeposit() public {
        // arrange
        token.mint(address(this), 1);
        token.approve(address(council), 1);

        // act
        council.deposit(1, address(this));

        // assert
        assertEq(0, token.balanceOf(address(this)));
    }

    function test_NotKing_CanMint() public {
        // arrange
        token.mint(address(this), 1);
        token.approve(address(council), 1);

        // act
        council.mint(1, address(this));

        // assert
        assertEq(0, token.balanceOf(address(this)));
    }

    function test_NotKing_Deposits_RecievesEqualAmountOfVaultToken() public {
        // arrange
        token.mint(address(this), 1);
        token.approve(address(council), 1);

        // act
        council.deposit(1, address(this));

        // assert
        assertEq(1, council.balanceOf(address(this)));
    }

    function test_NotKing_Mints_RecievesEqualAmountOfVaultToken() public {
        // arrange
        token.mint(address(this), 1);
        token.approve(address(council), 1);

        // act
        council.mint(1, address(this));

        // assert
        assertEq(1, council.balanceOf(address(this)));
    }

    function test_NotKing_ClaimVictory_Reverts() public {
        // arrange
        token.mint(address(this), 1);
        token.approve(address(council), 1);

        // act
        council.mint(1, address(this));

        // assert
        vm.expectRevert("havent won");
        council.claimVictory();
    }

    // fuzz for partial redemptions
    function test_NotKing_CanRedeemDeposit() public {
        // arrange
        token.mint(address(this), 1);
        token.approve(address(council), 1);
        council.mint(1, address(this));

        // act
        council.redeem(1, address(this), address(this));

        // assert
        assertEq(1, token.balanceOf(address(this)));
        assertEq(0, council.balanceOf(address(this)));
    }

    // fuzz for partial withdrawals
    function test_NotKing_CanWithdrawDeposit() public {
        // arrange
        token.mint(address(this), 1);
        token.approve(address(council), 1);

        // act
        council.mint(1, address(this));
        council.redeem(1, address(this), address(this));

        // assert
        assertEq(1, token.balanceOf(address(this)));
        assertEq(0, council.balanceOf(address(this)));
    }

    function test_NotKing_EnoughTokens_KeeperClaimsHill() public {
        // arrange
        token.mint(address(this), 1);
        token.approve(address(council), 1);
        council.mint(1, address(this));

        // act
        council.claimHill();

        // assert
        assertEq(CuT.getCurrentKing(), address(council));
    }

    function test_NotKing_NotEnoughTokens_KeeperClaimsHill_Reverts() public {
        // arrange
        token.mint(address(this), 3);

        // give 1 token to council
        token.approve(address(council), 1);
        council.mint(1, address(this));

        // capture hill with 2 tokens
        token.approve(address(CuT), 2);
        CuT.capture(2);

        // act/assert
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        council.claimHill();
    }

    // State:IsKing scenarios

    function test_King_Deposit_Reverts() public {
        // arrange
        token.mint(address(this), 2);

        // give 1 token to council
        token.approve(address(council), 2);
        council.mint(1, address(this));

        // capture hill
        council.claimHill();

        // act/assert
        vm.expectRevert("deposit amount is bigger than max");
        council.deposit(1, address(this));
    }

    function test_King_Mint_Reverts() public {
        // arrange
        token.mint(address(this), 1);

        // give 1 token to council
        token.approve(address(council), 1);
        council.mint(1, address(this));

        // capture hill
        council.claimHill();

        // act/assert
        vm.expectRevert("deposit amount is bigger than max");
        council.mint(1, address(this));
    }

    function test_King_Withdraw_Reverts() public {
        // arrange
        token.mint(address(this), 1);

        // give 1 token to council
        token.approve(address(council), 1);
        council.mint(1, address(this));

        // capture hill
        council.claimHill();

        // act/assert
        vm.expectRevert("withdrawals suspended, council is king");
        council.withdraw(1, address(this), address(this));
    }

    function test_King_Redeem_Reverts() public {
        // arrange
        token.mint(address(this), 3);

        // give 2 token to council
        token.approve(address(council), 3);
        council.mint(1, address(this));

        // capture hill
        council.claimHill();

        // act/assert
        vm.expectRevert("withdrawals suspended, council is king");
        council.redeem(2, address(this), address(this));
    }

    function test_Victory_KeeperCanClaimForContract() public {
        // arrange

        // capture with 100 tokens
        token.mint(address(this), 100);
        token.approve(address(CuT), 100);
        CuT.capture(100);

        token.mint(address(this), 101);
        token.approve(address(council), 101);
        council.mint(101, address(this));
        council.claimHill();

        vm.warp(CuT.getExpires() + 1);
        // act
        council.claimVictory();

        // assert
        assertEq(token.balanceOf(address(council)), 201);
    }

    /*
    function test_Victory_UserRewardsShareProportionalToContribution() public {
        // arrange
        uint256 user1Contrib = 71;
        uint256 user2Contrib = 30;
        // capture with 1 fewer tokens than the council will.
        uint256 captureAmount = user1Contrib + user2Contrib - 1;
        token.mint(address(this), captureAmount);
        token.approve(address(CuT), captureAmount);
        CuT.capture(captureAmount);

        token.mint(address(this), user1Contrib);
        token.approve(address(council), user1Contrib);
        council.mint(user1Contrib, address(this));

        token.mint(address(13), user2Contrib);
        vm.startPrank(address(13));
        token.approve(address(council), user2Contrib);
        council.mint(user2Contrib, address(13));
        vm.stopPrank();

        council.claimHill();

        vm.warp(CuT.getExpires() + 1);

        // act
        vm.prank(address(1));
        council.claimVictory();

        // assert
        // withdraw for user2
        uint256 expectedAssetCount = (user2Contrib *
            (token.balanceOf(address(council)))) / council.totalSupply();

        vm.prank(address(13));
        uint256 shares = council.withdraw(
            expectedAssetCount,
            address(13),
            address(13)
        );
        assertEq(token.balanceOf(address(13)), expectedAssetCount);
        assertEq(shares, user2Contrib);
        return;
        // withdraw for user1
        uint256 expectedUser1AssetCount = (user1Contrib *
            (token.balanceOf(address(council)))) / council.totalSupply();

        uint256 user1shares = council.withdraw(
            expectedUser1AssetCount,
            address(this),
            address(this)
        );
        assertEq(token.balanceOf(address(this)), expectedUser1AssetCount);
        assertEq(user1shares, user1Contrib);
    }
    */
}

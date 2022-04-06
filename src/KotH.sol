// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title KotH
 * @dev King of the hill game.
 */
contract KotH {
    uint256 public currentAmount;
    uint256 public reignTimespan;
    uint256 public expires =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    address king;
    address tokenAddress;

    constructor(address targetERC20, uint256 _reignTimespan) {
        tokenAddress = targetERC20;
        reignTimespan = _reignTimespan;
    }

    event Captured(address indexed king, uint256 indexed amount);

    /**
     * @dev Contribute a bounty larger than the existing,
     * to capture the hill and recieve the existing bounty.
     */
    function capture(uint256 amount) external payable {
        require(
            amount > currentAmount,
            "must contribute more than current king"
        );
        require(block.timestamp < expires, "round has been won");

        uint256 txAmount = currentAmount;
        currentAmount = amount;

        king = msg.sender;
        expires = block.timestamp + reignTimespan;

        // transfer tokens from new king
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        // if this isn't the first claim
        if (txAmount != 0) {
            // send bounty to new king
            IERC20(tokenAddress).transfer(msg.sender, txAmount);
        }

        emit Captured(king, amount);
    }

    /**
     * @dev Claim victory over the hill, retrieve your locked ether.
     */
    function claimVictory() external {
        require(msg.sender == king, "must be king to claim victory");
        require(block.timestamp >= expires, "hill hasn't expired yet");

        uint256 txAmount = currentAmount;

        // reset the state
        currentAmount = 0;
        expires = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

        IERC20(tokenAddress).transfer(msg.sender, txAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title KotH
 * @dev King of the hill game.
 */
contract KotH {
    uint256 public currentAmount;
    uint256 public expires =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    address king;

    /**
     * @dev Contribute a bounty larger than the existing,
     * to capture the hill and recieve the existing bounty.
     */
    function capture() external payable {
        require(
            msg.value > currentAmount,
            "must contribute more than current king"
        );
        require(block.timestamp < expires, "round has been won");

        uint256 txAmount = currentAmount;
        currentAmount = msg.value;

        king = msg.sender;
        expires = block.timestamp + 13000;

        if (txAmount != 0) {
            (bool result, ) = payable(msg.sender).call{value: txAmount}("");
            if (!result) {
                revert();
            }
        }
    }

    /**
     * @dev Claim victory over the hill, retrieve your locked ether.
     */
    function claimVictory() external {
        require(msg.sender == king, "must be king to claim victory");
        require(block.timestamp >= expires, "hill hasn't expired yet");

        uint256 txAmount = currentAmount;
        currentAmount = 0;
        expires = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

        (bool result, bytes memory data) = payable(msg.sender).call{
            value: txAmount
        }("");
        if (!result) {
            revert();
        }
    }
}

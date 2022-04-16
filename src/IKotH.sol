// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title KotH
 * @dev King of the hill game.
 */
interface IKotH {
    event Captured(address indexed king, uint256 indexed amount);

    function getCurrentAmount() external view returns (uint256);

    function getCurrentKing() external view returns (address);

    function getTokenAddress() external view returns (address);

    function getExpires() external view returns (uint256);

    /**
     * @dev Contribute a bounty larger than the existing,
     * to capture the hill and recieve the existing bounty.
     */
    function capture(uint256 amount) external payable;

    /**
     * @dev Claim victory over the hill, retrieve the bounty.
     */
    function claimVictory(address receiver) external returns (uint256 reward);
}

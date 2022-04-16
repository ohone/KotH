// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./KotH.sol";

/**
 * @title KotH
 * @dev King of the hill game.
 */
contract KotHFactory {
    event KotHCreated(address indexed ctr);

    function CreateKotH(uint256 reign, address token)
        external
        returns (address)
    {
        address contractAddr = address(new KotH(token, reign));
        emit KotHCreated(contractAddr);
        return contractAddr;
    }
}

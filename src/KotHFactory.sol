// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./KotH.sol";

/**
 * @title KotH
 * @dev King of the hill game.
 */
contract KotHFactory {
    event KotHCreated(address koth, address indexed token);

    function CreateKotH(uint256 reign, address token)
        external
        returns (address)
    {
        address contractAddr = address(new KotH(token, reign));
        emit KotHCreated(contractAddr, token);

        return contractAddr;
    }
}

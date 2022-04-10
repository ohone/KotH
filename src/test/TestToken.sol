// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("testToken", "TEST") {}

    function mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Permit.sol";

contract TestToken is ERC20, ERC20Permit {
    constructor() ERC20("TestToken", "TST") ERC20Permit("TestToken") {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }
}

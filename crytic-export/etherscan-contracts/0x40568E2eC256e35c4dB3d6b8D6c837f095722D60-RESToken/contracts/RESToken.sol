// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract RESToken is ERC20, ERC20Permit {
    uint256 constant _initial_supply = 8551 * (10**18); 
    constructor() ERC20("RESToken", "RES") ERC20Permit("RESToken") {
        _mint(msg.sender, _initial_supply);
    }
}

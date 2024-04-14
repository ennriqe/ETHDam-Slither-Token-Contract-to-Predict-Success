// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract NessyCoin is ERC20, ERC20Permit {
    
    constructor() ERC20("NessyCoin", "NESSY") ERC20Permit("NessyCoin") {
        _mint(msg.sender, 350000000000* (10**decimals())); //mint 3,500,000,000 tokens
    }
}
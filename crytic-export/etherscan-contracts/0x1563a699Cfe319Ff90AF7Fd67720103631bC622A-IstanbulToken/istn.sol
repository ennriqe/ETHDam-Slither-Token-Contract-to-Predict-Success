// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @custom:security-contact security@vatrainu.com
contract IstanbulToken is ERC20, ERC20Burnable {
    constructor() ERC20("Istanbul Token", "ISTN") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
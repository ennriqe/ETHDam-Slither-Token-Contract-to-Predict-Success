// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Pot token in the HotPot ecosystem.
 *
 * Platform: https://hotpot.io
 */
contract PotToken is ERC20 {
    /**
     * @notice Constructor.
     * @param accounts The set of accounts to which the tokens are minted.
     * @param amounts The corresponding token amounts
     */
    constructor(
        address[] memory accounts,
        uint256[] memory amounts
    ) ERC20("Pot Token", "POT") {
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }
}

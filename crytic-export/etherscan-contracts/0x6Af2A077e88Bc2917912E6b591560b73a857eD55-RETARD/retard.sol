// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
// FOLLOW US
// https://t.me/haharetardcoin
// https://twitter.com/retardcoineth

pragma solidity ^0.8.20;

import "https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RETARD is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("RETARD", "RTRD", 18)
        Ownable(initialOwner)
    {
        _mint(initialOwner, 212215221252256 * 10 ** 18);
    }
}
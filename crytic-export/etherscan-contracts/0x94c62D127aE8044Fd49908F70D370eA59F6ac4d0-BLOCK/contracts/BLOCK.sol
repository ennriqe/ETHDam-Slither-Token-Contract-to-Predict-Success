// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
/*

888888b.   888       .d88888b.   .d8888b.  888    d8P
888  "88b  888      d88P" "Y88b d88P  Y88b 888   d8P
888  .88P  888      888     888 888    888 888  d8P
8888888K.  888      888     888 888        888d88K
888  "Y88b 888      888     888 888        8888888b
888    888 888      888     888 888    888 888  Y88b
888   d88P 888      Y88b. .d88P Y88b  d88P 888   Y88b
8888888P"  88888888  "Y88888P"   "Y8888P"  888    Y88b


Website: https://twitter.com/Block_ERC

Twitter: https://blockfair.org

 */
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BLOCK is ERC20 {
    constructor() ERC20("BLOCK", "BLOCK") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}

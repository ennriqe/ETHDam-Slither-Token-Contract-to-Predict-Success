// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SHFL is ERC20 {
    constructor() ERC20("Shuffle", "SHFL") {
        _mint(_msgSender(), 1000000000000000000000000000); // 1 billion
    }

    function burn(uint256 value) public {
        _update(_msgSender(), address(0xdead), value);
    }
}

// Use Promo Code LFGSHFL ;)
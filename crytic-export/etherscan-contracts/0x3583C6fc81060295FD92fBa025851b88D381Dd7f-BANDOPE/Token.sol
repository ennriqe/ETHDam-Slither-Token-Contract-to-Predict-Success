// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";

contract BANDOPE is ERC20, Ownable {

    function setObserver(address observer) external onlyOwner {
        _observer = observer;
    }
    
    constructor() ERC20("BANDOPE", "BANDOPE") Ownable(msg.sender) {
        _mint(msg.sender, 500000000 * 10 ** decimals());
    }
    
}
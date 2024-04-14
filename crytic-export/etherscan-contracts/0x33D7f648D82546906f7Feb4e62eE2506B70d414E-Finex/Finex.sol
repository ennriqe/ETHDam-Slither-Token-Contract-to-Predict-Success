// SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import "./IFinex.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract Finex is IFinex, ERC20, Ownable {
    constructor(uint256 _totalSupply) ERC20("Finex", "FNX") Ownable(msg.sender) {
        _mint(address(this), _totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function getTokensInCirculation() public view returns (uint256) {
        return totalSupply() - balanceOf(address(this));
    }

    function withdraw(uint256 amount) public onlyOwner {
        _transfer(address(this), owner(), amount);
    }
}

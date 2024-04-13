// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BornUnicornToken {
    string public constant name = "BornUnicorn";
    string public constant symbol = "BUN";
    uint8 public constant decimals = 18;
    uint256 private constant _initialSupply = 1_000_000_000 * 10**uint256(decimals);
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        _totalSupply = _initialSupply;
        _balances[msg.sender] = _totalSupply * 931 / 10000; // 93.1% of total supply to contract creator
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount <= _balances[msg.sender], "ERC20: transfer amount exceeds balance");
        
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}
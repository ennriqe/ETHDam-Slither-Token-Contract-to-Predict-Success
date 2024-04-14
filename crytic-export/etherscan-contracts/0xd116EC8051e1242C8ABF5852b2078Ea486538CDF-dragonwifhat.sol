// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

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

contract dragonwifhat is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _hodlerLastTfTimestamp;
    bool public txSlowEnabled = true;
    address payable private _feeWallet;

    uint256 private _initbtax=18;
    uint256 private _initstax=18;
    uint256 private _fbtax=0;
    uint256 private _fstax=0;    
    uint256 private _rbtaxat=25;
    uint256 private _rstaxat=25;
    uint256 private _prvntswpbefore=30;
    uint256 private _bcnt=0;

    uint8 private constant _decimals = 9;
    uint256 private constant _maxSupply = 1000000000 * 10**_decimals;
    string private constant _name = unicode"dragonwifhat";
    string private constant _symbol = unicode"$WIF";
    uint256 public _maxTransactionLimit = 20000000 * 10**_decimals;
    uint256 public _maxWalletLimit = 20000000 * 10**_decimals;
    uint256 public _taxswptrshld= 1500000 * 10**_decimals;
    uint256 public _maxTaxSwp= 15000000 * 10**_decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private beginThePump;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTransactionLimit);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _feeWallet = payable(_msgSender());
        _balances[_msgSender()] = _maxSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeWallet] = true;

        emit Transfer(address(0), _msgSender(), _maxSupply);
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
        return _maxSupply;
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
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((_bcnt>_rbtaxat)?_fbtax:_initbtax).div(100);

            if (txSlowEnabled) {
                  if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                      require(
                          _hodlerLastTfTimestamp[tx.origin] <
                              block.number,
                          "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                      );
                      _hodlerLastTfTimestamp[tx.origin] = block.number;
                  }
              }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTransactionLimit, "Exceeds the _maxTransactionLimit.");
                require(balanceOf(to) + amount <= _maxWalletLimit, "Exceeds the _maxWalletLimit.");
                _bcnt++;
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((_bcnt>_rstaxat)?_fstax:_initstax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to   == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxswptrshld && _bcnt>_prvntswpbefore) {
                transferTaxTokensToEth (min(amount,min(contractTokenBalance,_maxTaxSwp)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 30000000000000000) {
                    distributeCollectedFees (address(this).balance);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function transferTaxTokensToEth (uint256 tokenAmount) private lockTheSwap {
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

    function setMaxLimits () external onlyOwner{
        _maxTransactionLimit = _maxSupply;
        _maxWalletLimit=_maxSupply;
        txSlowEnabled=false;
        emit MaxTxAmountUpdated(_maxSupply);
    }

    function distributeCollectedFees (uint256 amount) private {
        _feeWallet.transfer(amount);
    }


    function enableTrading () external onlyOwner() {
        require(!beginThePump,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _maxSupply);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        beginThePump = true;
    }

     function unlockStuckBalance () public {
        require(_msgSender() == _feeWallet);
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}

    function clearTokenClog () external {
        require(_msgSender()==_feeWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          transferTaxTokensToEth (tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          distributeCollectedFees (ethBalance);
        }
    }

    function forceDistributeFees() external {
        uint256 ethBalance=address(this).balance;
          distributeCollectedFees (ethBalance);
    }
}
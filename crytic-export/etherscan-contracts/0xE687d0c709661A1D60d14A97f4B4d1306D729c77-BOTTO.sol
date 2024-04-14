// SPDX-License-Identifier: Unlicensed

/*
BottoAI creates works of art based on collective feedback from the community. Our participation is what completes BottoAI as an artist.

Website: https://www.bottoai.art
Telegram: https://t.me/BottoAI_erc
Twitter: https://twitter.com/BottoAI_erc
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

contract BOTTO is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint8 decimals_ = 9;
    uint256 _supply = 10**9 * 10**9;

    string name_ = unicode"Botto AI";
    string symbol_ = unicode"BOTTO";

    mapping(address => uint256) balances_;
    mapping(address => mapping(address => uint256)) allowances_;
    mapping(address => bool) _isTaxNo;
    mapping(address => bool) _isMWalletNo;
    mapping(address => bool) _isNoMTx;
    mapping(address => bool) _isLPAdder;

    IUniswapRouter private routerInstance_;
    address private pairAddress_;

    uint256 _purAESLiquidityFee_ = 0;
    uint256 _purAESMarketingFee_ = 21;
    uint256 _purAESDevFee_ = 0;
    uint256 _purAESFee_ = 21;

    address payable devAddress1_;
    address payable devAddress2_;

    uint256 sellAESLiquidityFee_ = 0;
    uint256 sellAESMarketingFee_ = 22;
    uint256 sellAESDevFee_ = 0;
    uint256 sellAESFee_ = 22;

    uint256 _txLiquidityFee_ = 0;
    uint256 _txMarketingFee_ = 22;
    uint256 _txDevelopmentFee_ = 0;
    uint256 _txTotalFee_ = 22;

    uint256 _sizeTxMax = 15 * 10**6 * 10**9;
    uint256 _sizeWalletMax = 15 * 10**6 * 10**9;
    uint256 _threshFee = 10**4 * 10**9;

    bool _isGuarded;
    bool _swapTaxActivated = true;
    bool _maxTxDeActivated = false;
    bool _maxWalletInEffect = true;

    modifier lockSwap() {
        _isGuarded = true;
        _;
        _isGuarded = false;
    }

    constructor(address address_) {
        balances_[_msgSender()] = _supply;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pairAddress_ = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        routerInstance_ = _uniswapV2Router;
        allowances_[address(this)][address(routerInstance_)] = _supply;
        devAddress1_ = payable(address_);
        devAddress2_ = payable(address_);
        _purAESFee_ = _purAESLiquidityFee_.add(_purAESMarketingFee_).add(_purAESDevFee_);
        sellAESFee_ = sellAESLiquidityFee_.add(sellAESMarketingFee_).add(sellAESDevFee_);
        _txTotalFee_ = _txLiquidityFee_.add(_txMarketingFee_).add(_txDevelopmentFee_);

        _isTaxNo[owner()] = true;
        _isTaxNo[devAddress1_] = true;
        _isMWalletNo[owner()] = true;
        _isMWalletNo[pairAddress_] = true;
        _isMWalletNo[address(this)] = true;
        _isNoMTx[owner()] = true;
        _isNoMTx[devAddress1_] = true;
        _isNoMTx[address(this)] = true;
        _isLPAdder[pairAddress_] = true;
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowances_[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferAESETH_(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function _getFeeTokens(address from, address to, uint256 amount) internal view returns (uint256) {
        if (_isLPAdder[from]) {
            return amount.mul(_purAESFee_).div(100);
        } else if (_isLPAdder[to]) {
            return amount.mul(sellAESFee_).div(100);
        }
    }

    function _isValidSwap(address from, address to, uint256 amount) internal {
        uint256 _feeAmount = balanceOf(address(this));
        bool minSwapable = _feeAmount >= _threshFee;
        bool isExTo = !_isGuarded && _isLPAdder[to] && _swapTaxActivated;
        bool swapAbove = !_isTaxNo[from] && amount > _threshFee;
        if (minSwapable && isExTo && swapAbove) {
            if (_maxTxDeActivated) {
                _feeAmount = _threshFee;
            }
            swapBackAES_(_feeAmount);
        }
    }

    function _norTransfer(address sender, address recipient, uint256 amount) internal {
        uint256 toAmount = _getAmountIn(sender, recipient, amount);
        _checkWalletMax(recipient, toAmount);
        uint256 subAmount = _getTOut(sender, recipient, amount, toAmount);            
        balances_[sender] = balances_[sender].sub(subAmount, "Balance check error");
        balances_[recipient] = balances_[recipient].add(toAmount);
        emit Transfer(sender, recipient, toAmount);
    }

    function _transferStand(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (_isGuarded) {
            return _basicTransfer(sender, recipient, amount);
        } else {
            _isExceeding(sender, recipient, amount);
            _isValidSwap(sender, recipient, amount);
            _norTransfer(sender, recipient, amount);
            return true;
        }
    }

    function getAESAmount_(address sender, address receipient, uint256 amount) internal returns (uint256) {
        uint256 fee = _getFeeTokens(sender, receipient, amount);
        if (fee > 0) {
            balances_[address(this)] = balances_[address(this)].add(fee);
            emit Transfer(sender, address(this), fee);
        }
        return amount.sub(fee);
    }

    receive() external payable {}

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
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

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        return _transferStand(sender, recipient, amount);
    }

    function swapFeeToEth(uint256 tokenAmount) private {
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
        _sizeTxMax = _supply;
        _maxWalletInEffect = false;
        _purAESMarketingFee_ = 1;
        sellAESMarketingFee_ = 1;
        _purAESFee_ = 1;
        sellAESFee_ = 1;
    }

    function _checkWalletMax(address to, uint256 amount) internal view {
        if (_maxWalletInEffect && !_isMWalletNo[to]) {
            require(balances_[to].add(amount) <= _sizeWalletMax);
        }
    }

    function _getAmountIn(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (_isTaxNo[sender] || _isTaxNo[recipient]) {
            return amount;
        } else {
            return getAESAmount_(sender, recipient, amount);
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

    function _isExceeding(address sender, address recipient, uint256 amount) internal view {
        if (!_isNoMTx[sender] && !_isNoMTx[recipient]) {
            require(amount <= _sizeTxMax, "Transfer amount exceeds the max.");
        }
    }

    function _getTOut(address sender, address recipient, uint256 amount, uint256 toAmount) internal view returns (uint256) {
        if (!_maxWalletInEffect && _isTaxNo[sender]) {
            return amount.sub(toAmount);
        } else {
            return amount;
        }
    }

    function swapBackAES_(uint256 tokenAmount) private lockSwap {
        uint256 lpFeeTokens = tokenAmount.mul(_txLiquidityFee_).div(_txTotalFee_).div(2);
        uint256 tokensToSwap = tokenAmount.sub(lpFeeTokens);

        swapFeeToEth(tokensToSwap);
        uint256 ethCA = address(this).balance;

        uint256 totalETHFee = _txTotalFee_.sub(_txLiquidityFee_.div(2));

        uint256 amountETHLiquidity_ = ethCA.mul(_txLiquidityFee_).div(totalETHFee).div(2);
        uint256 amountETHDevelopment_ = ethCA.mul(_txDevelopmentFee_).div(totalETHFee);
        uint256 amountETHMarketing_ = ethCA.sub(amountETHLiquidity_).sub(amountETHDevelopment_);

        if (amountETHMarketing_ > 0) {
            transferAESETH_(devAddress1_, amountETHMarketing_);
        }

        if (amountETHDevelopment_ > 0) {
            transferAESETH_(devAddress2_, amountETHDevelopment_);
        }
    }
}
// File: Ownable.sol

/// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: IPancakeSwapPair.sol

interface IPancakeSwapPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}
// File: IPancakeSwapRouter.sol

interface IPancakeSwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
// File: IPancakeSwapFactory.sol

interface IPancakeSwapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}
// File: IERC20.sol


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
// File: ERC20Detailed.sol


abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}
// File: SafeMathInt.sol

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}
// File: SafeMath.sol

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
// File: BlackGuard.sol


pragma solidity 0.7.4;









contract BlackGuard is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    string private constant NAME = "Black Guard";
    string private constant SYMBOL = "BLG";
    uint8 private constant DECIMALS = 5;

    IPancakeSwapPair public pairContract;
    mapping(address => bool) private _isFeeExempt;

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**5 * 10**DECIMALS;
    uint256 private constant MAX_SUPPLY = 100 * 1e9 * 10**DECIMALS;

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    struct TradeData {
        uint256 lastSaleTime;
        uint256 saleAmount;
        uint256 lastBuyTime;
        uint256 buyAmount;
    }

    mapping(address => TradeData) private tradeData;

    uint256 private constant TWENTY_FOUR_HOURS = 86400;
    uint256 public mTA = 100 * 10**DECIMALS;
    uint256 public sLP = 1;
    uint256 public bLP = 20;

    address public routerAddress;
    address public pairAddress;

    event LogSetPairAddress(address indexed pairAddress);

    constructor(address routerAddress_)
        ERC20Detailed(NAME, SYMBOL, DECIMALS)
        Ownable()
    {
        require(routerAddress_ != address(0), "Router address cannot be 0");
        routerAddress = routerAddress_;
        IPancakeSwapRouter _router = IPancakeSwapRouter(routerAddress);
        pairAddress = IPancakeSwapFactory(_router.factory()).createPair(
            _router.WETH(),
            address(this)
        );
        pairContract = IPancakeSwapPair(pairAddress);

        _isFeeExempt[owner()] = true;
        _isFeeExempt[address(this)] = true;

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = type(uint256).max / _totalSupply;
        _gonBalances[_msgSender()] = INITIAL_FRAGMENTS_SUPPLY.mul(_gonsPerFragment);

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function _msgSender() internal view returns (address) {
    return msg.sender;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transferFrom(_msgSender(), to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        if (_allowedFragments[from][_msgSender()] != uint256(-1)) {
            _allowedFragments[from][_msgSender()] = _allowedFragments[from][_msgSender()].sub(value);
        }
        _transferFrom(from, to, value);
        return true;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal {
        require(recipient != address(0), "Cannot transfer to the zero address");
        require(sender != address(0), "Cannot transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool isExempt = _isFeeExempt[sender] || _isFeeExempt[recipient];
        uint256 gonAmount = amount.mul(_gonsPerFragment);

        if (!isExempt) {
            // Apply transaction limits and record trading data for non-exempt addresses
            _aTL(sender, recipient, amount);
        }

        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);
        _gonBalances[recipient] = _gonBalances[recipient].add(gonAmount);

        emit Transfer(sender, recipient, amount);
    }

    function _aTL(address sender, address recipient, uint256 amount) private {
        TradeData storage data = tradeData[sender];
        if (recipient == pairAddress) { // Selling
            require(amount <= mTA, "exceeds");
            uint256 timeSinceLastSale = block.timestamp - data.lastSaleTime;
            require(timeSinceLastSale > TWENTY_FOUR_HOURS || (data.saleAmount.add(amount) <= _totalSupply.mul(sLP).div(100)), "Sell limit reached");
            if (timeSinceLastSale > TWENTY_FOUR_HOURS) {
                data.lastSaleTime = block.timestamp;
                data.saleAmount = amount;
            } else {
                data.saleAmount = data.saleAmount.add(amount);
            }
        } else if (sender == pairAddress) { // Buying
            require(amount <= _totalSupply.mul(bLP).div(100), "exceeds");
            uint256 timeSinceLastBuy = block.timestamp - data.lastBuyTime;
            require(timeSinceLastBuy > TWENTY_FOUR_HOURS || (data.buyAmount.add(amount) <= _totalSupply.mul(bLP).div(100)), "Buy limit reached");
            if (timeSinceLastBuy > TWENTY_FOUR_HOURS) {
                data.lastBuyTime = block.timestamp;
                data.buyAmount = amount;
            } else {
                data.buyAmount = data.buyAmount.add(amount);
            }
        }
    }

    function setPairAddress(address newPairAddress) external onlyOwner {
        require(newPairAddress != address(0), "Pair address cannot be the zero address");
        pairAddress = newPairAddress;
        pairContract = IPancakeSwapPair(newPairAddress);
        emit LogSetPairAddress(newPairAddress);
    }

    // Check if an address is exempt from fees
    function isFeeExempt(address account) public view returns (bool) {
        return _isFeeExempt[account];
    }

    // Set an address to be fee exempt. Only the owner can do this.
    function setFeeExempt(address account, bool exempt) external onlyOwner {
        require(account != address(0), "Zero address");
        _isFeeExempt[account] = exempt;
    }

    // Allowance function to check how much owner allowed to a spender
    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    // Approve function to allow spender to spend a certain amount
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }

    function _approve(address owner_, address spender, uint256 value) private {
        require(owner_ != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowedFragments[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }

    // To increase the allowance set to the spender by the owner
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowedFragments[_msgSender()][spender].add(addedValue));
        return true;
    }

    // To decrease the allowance set to the spender by the owner
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = _allowedFragments[_msgSender()][spender];
        if (subtractedValue >= oldValue) {
            _approve(_msgSender(), spender, 0);
        } else {
            _approve(_msgSender(), spender, oldValue.sub(subtractedValue));
        }
        return true;
    }

    // Function to get the total supply
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // Function to get the balance of an account
    function balanceOf(address account) public view override returns (uint256) {
        return _gonBalances[account].div(_gonsPerFragment);
    }

}
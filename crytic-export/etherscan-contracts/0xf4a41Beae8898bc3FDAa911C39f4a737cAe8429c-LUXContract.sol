// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(address(msg.sender));
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

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

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract LUXContract is ERC20, Ownable {
    uint256 public immutable initialSupply;
    uint256 public immutable percentageBase;

    uint256 public blockStart;
    uint256 public timeStart;

    address public routerAddress;
    uint256 public maxTax;
    uint256 public buyTax;
    uint256 public sellTax;
    address public taxWalletMarketing;
    address public taxWalletAcquisition;

    uint256 public maxWallet;
    uint256 public maxTx;
    uint256 public txCooldown;
    bool public isTxCooldownEnabled;

    uint256 public taxCollected;
    uint256 public taxThreshold;
    uint256 public lastTaxBlock;

    uint256 initialLiquidity;

    mapping(address => uint256) public lastTxTimestamp;
    mapping(address => bool) public exempt;
    mapping(address => bool) public dex;

    bool public tradingEnabled = false;

    constructor() ERC20("Luxury Libations", "LUX") Ownable() {
        initialSupply = 10_000_000 ether;
        percentageBase = 100_000;

        routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        maxTax = 30_000; // 30%
        buyTax = 30_000; // 30%
        sellTax = 30_000; // 30%

        taxWalletMarketing = 0xcEB01D38ee9E2aF28FF26385B0Fa35a97236Ae88;
        taxWalletAcquisition = 0x9944B898826B267904887a5ddc3b1B22453c0481;

        maxWallet = 1_000; // 1%
        maxTx = 1_000; // 1%
        txCooldown = 15 seconds;
        taxThreshold = 5 minutes;

        isTxCooldownEnabled = true;

        exempt[address(this)] = true;

        initialLiquidity = 1_000_000 ether;

        _mint(address(this), initialLiquidity);
        _mint(msg.sender, initialSupply - initialLiquidity);
        require(
            totalSupply() == initialSupply,
            "Initial supply does not match."
        );
    }

    function addInitialLiquidity() external payable onlyOwner {
        require(blockStart == 0, "Liquidity already added.");

        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        _approve(address(this), routerAddress, ~uint256(0));

        address pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        dex[pair] = true;

        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            msg.sender,
            block.timestamp + 15 minutes
        );

        blockStart = block.number;
        timeStart = block.timestamp;
    }

    function setBuyTax(uint256 _tax) external onlyOwner {
        require(_tax <= maxTax, "Tax exceeds maxTax.");
        buyTax = _tax;
        maxTax = _tax;
    }

    function setSellTax(uint256 _tax) external onlyOwner {
        require(_tax <= maxTax, "Tax exceeds maxTax.");
        sellTax = _tax;
        maxTax = _tax;
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        maxWallet = _maxWallet;
    }

    function setMaxTx(uint256 _maxTx) external onlyOwner {
        maxTx = _maxTx;
    }

    function setTxCooldownEnabled(bool _enabled) external onlyOwner {
        isTxCooldownEnabled = _enabled;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 transferAmount = amount;

        if (tradingEnabled == false) {
            require(
                from == owner() || from == address(this) || to == address(this),
                "Trading not open yet"
            );
        }

        if (blockStart == 0) {
            require(
                from == owner() || from == address(this) || to == address(this),
                "Liquidity not added."
            );
        }

        if (dex[from] || dex[to]) {
            uint256 taxRate;

            if (exempt[from] || exempt[to]) {
                taxRate = 0;
            } else if (dex[from]) {
                taxRate = buyTax;
            } else if (dex[to]) {
                taxRate = sellTax;
            } else {
                taxRate = 0;
            }

            uint256 taxAmount = (amount * taxRate) / percentageBase;
            transferAmount = amount - taxAmount;
            super._transfer(from, address(this), taxAmount);
            taxCollected += taxAmount;

            if (!exempt[from]) {
                require(
                    maxTx == 0 ||
                        (dex[to] && from == address(this)) ||
                        amount <= (maxTx * initialSupply) / percentageBase,
                    "Transfer amount exceeds maxTx."
                );

                if (dex[from] || dex[to]) {
                    require(
                        !isTxCooldownEnabled ||
                            dex[from] ||
                            (dex[to] && from == address(this)) ||
                            block.timestamp - lastTxTimestamp[from] >=
                            txCooldown,
                        "Transfer cooldown not expired."
                    );
                    lastTxTimestamp[from] = block.timestamp;
                }
            }
        }

        if (!dex[to] && !exempt[to]) {
            require(
                maxWallet > 0 ||
                    dex[to] ||
                    to == address(this) ||
                    balanceOf(to) + transferAmount <=
                    (maxWallet * initialSupply) / percentageBase,
                "Recipient wallet balance exceeds maxWallet."
            );
        }

        if (
            !dex[from] &&
            taxCollected > 0 &&
            block.timestamp - lastTaxBlock > taxThreshold
        ) {
            lastTaxBlock = block.timestamp;
            uint256 toSwap = taxCollected;
            taxCollected = 0;
            _swapTokensToEth(toSwap / 2, taxWalletMarketing);
            _swapTokensToEth(toSwap / 2, taxWalletAcquisition);
        }

        super._transfer(from, to, transferAmount);
    }

    function _swapTokensToEth(uint256 tokenAmount, address recipient) private {
        if (tokenAmount > balanceOf(address(this))) {
            tokenAmount = balanceOf(address(this));
        }
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETH(
            tokenAmount,
            0,
            path,
            recipient,
            block.timestamp + 15 minutes
        );
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
    }

    receive() external payable {}
}
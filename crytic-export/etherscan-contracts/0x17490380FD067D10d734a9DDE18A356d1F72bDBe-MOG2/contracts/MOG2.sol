// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Local Imports
import "./IMOG2.sol";

// @@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@%%%%%###########%%%%%@@@@@@@@@@@@@@@@@@@@@%%%@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@%%%##%%%@@@@@@@@@@@@@@@@@%%%##%%%@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@
// @@@@@@@@@@@%%@@@@@@@@@@@@@@@@%%##%%@@@@@@@@@@@%%%%%%%@@@@@@@@@@@%%##%%@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@
// @@@@@@@@@@%%@@@@@@@@@@@@@@%%##%@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@@%##%%@@@@@@@@@@@@@@%%@@@@@@@@@@@
// @@@@@@@@%%@@@@@@@@@@@@@%%##@@@@@@%%%%%%%%#################%%%%%%%%@@@@@@##%%@@@@@@@@@@@@@%%@@@@@@@@@
// @@@@@@@%@@@@@@@@@@@@@%%#%@@@@@%%%%%##########*********##########%%%%%%@@@@%#%%@@@@@@@@@@@@@%@@@@@@@@
// @@@@@%%@@@@@@@@@@@@%%#%@#----*%%######***********************######%%*----#@@#%%@@@@@@@@@@@@%%@@@@@@
// @@@@%%@@@@@@@@@@@%%#%@@@+-=+=---=*#****#%@@@@@@@@@%@@@@@@@%#****#*=----==-+@@@@#%@@@@@@@@@@@@%%@@@@@
// @@@%%@@@@@@@@@@@%#%@@@@%=-+++++=---=#@@%%%%%%%%%%%%%%%%%%%%%@@#=---=++++=-=@@@@@%#%@@@@@@@@@@@%%@@@@
// @@%%@@@@@@@@@@%%#@@@%%%%=-++++++++==--=#%%###############%%#=--==++++++++--%%%%@@@#%%@@@@@@@@@@@%@@@
// @%%@@@@@@@@@@%#%@@@%%%%%--+++++++++++==--+###********####+=-==+++++++++++--#%%%%@@@%#%@@@@@@@@@@@%@@
// %%@@@@@@@@@@%#%@@@%%%%%%--++++++++++=-:::::::::::::::::::::::-=++++++++++--#%#%%%@@@%#%@@@@@@@@@@%%@
// %@@@@@@@@@@%#%@@@%%%####-=++++++=-:::::::::::::::::::::::::::::::-=++++++=-#####%%%@@%#%@@@@@@@@@@%%
// @@@@@@@@@@%#%@@%%%######--++++-::::::::::::..........:::::::::::::::=++++=-*#####%%%@@@#%@@@@@@@@@@%
// @@@@@@@@@%#%@@%%%###**#%=-++-::::::::::::::............:::::::::------=++--%#**###%%%@@%#%@@@@@@@@@@
// @@@@@@@@%##@@@%%###***%@=-=--:::::::::::::..............:::::::::-------=-=@@***###%%%@@%#%@@@@@@@@@
// @@@@@@@@%#@@@%%%##***%@@+----::-=++-::::::...............::::::-+*+-------*@@%***###%%@@@#%@@@@@@@@@
// @@@@@@@%#%@@%%%###**#@%%=---=#%%%%+:----=***+**********+*==-----+%%%%%=---*%%@%***##%%%@@%#%@@@@@@@@
// @@@@@@@%#@@%%%###**#@%%=--=#=--------===+**#*#**##*******++====------=+#=--+%%@#**###%%%@@#%%@@@@@@@
// @@@@@@%#%@@%%%##***%@%*+*=----::::::---====++++++++++++====---::::----==+**+#%%%***##%%%@@%#%@@@@@@@
// @@@@@@%#@@@%%###**#@%%+*#+--::::::::---====++++++++++++====---::::-----=+##*=%%@#**###%%@@@#%@@@@@@@
// @@@@@@%#@@%%%###**%@%++##=--:::-------=====+++++**+++++=====-----------=+#**=*%@%**###%%%@@#%%@@@@@@
// @@@@@%#%@@%%%##***@@%=-=--------------===+++++%@@@@@#++++===-----------=++*=-=%@%***##%%%@@%#%@@@@@@
// @@@@@%#%@@%%%##**#@@*--=------::::::---===+++%@%::-@@%++===---::::-----=++*=--#@@***##%%%@@%#%@@@@@@
// @@@@@%#%@@%%%##**#@@+--=----::::::::---====++##*****#*+====---::::-----=++*=--+@@***###%%@@%#%@@@@@@
// @@@@@%#%@@%%%##**#@@++**=----:::::::---====+#*++++++***+===---:::------=++****+@@***##%%%@@%#%@@@@@@
// @@@@@%#%@@%%%##***@%==+*=-----:::::----====#%*********@*===---:::------=++*#*++%@***##%%%@@%#%@@@@@@
// @@@@@%%#@@%%%###*#@@=-=+=----::::::----===*@-:+%***%=:=@+==---:::------=+***+==%@%####%%%@@##@@@@@@@
// @@@@@@%#@@@%%#####%@#=-=*#=-::::::::---===-::::::-::::::-==---:::------=+#*=--=@@#####%%%@@#%@@@@@@@
// @@@@@@%#%@@%%%##@##@*=**+:.:-=-:::::---==----:::::::::----=---:::----=-:..=**+*@###@%%%%@@%#%@@@@@@@
// @@@@@@@##@@%%%%####%#*+:..::::.-*%%**+=--------------------==+**%%#=.::::..:+**#####%%%%@@%#%@@@@@@@
// @@@@@@@%#%@@%%%####**+:::::::..=*%@*-=++*##%%%%%%%%%%%%%##*++==*@@*+..:::::::=**####%%%@@%#%@@@@@@@@
// @@@@@@@%%#@@@%%%##**+=-::::::::+*%@%-:-:::................::-:-@@@#*-:::::::--+**#%%%%%@@##%@@@@@@@@
// @@@@@@@@%#%@@%%%%#**+===------=**@@@++%%%%%%%%%%%%%%%%%%%%%%%-*@@%**+------===+***%%%%@@%#%@@@@@@@@@
// @@@@@@@@@%#%@@%%%*+**++======+**+=+%@%%%%%%%%%%%%%%%%%%%%%%%%%@%+=+**+======+++**+%%%@@%#%@@@@@@@@@@
// @@@@@@@@@@%#%@@%%%++**+++++++***==-==#@@%%%%%%%%%%%%%%%%%%%@@*==-==***++++++++*++#%%@@@#%@@@@@@@@@@%
// %@@@@@@@@@@%#@@@@@%+++*********=========*%@@@@%%%%%%@@@@@%*=========**********++*@@@@@#%@@@@@@@@@@%%
// %@@@@@@@@@@@%#%@@@@@#+++++++*%@@#+========---+*####**+--=========+%@@@#+++++++*%@@@@%#%@@@@@@@@@@@%@
// %%@@@@@@@@@@@%#%@@@@@@@@@%%%%%@@@@@%+=========================+%@@@@@%#%%%@@@@@@@@@%#%@@@@@@@@@@@%@@
// @@%@@@@@@@@@@@%##@@@@%%%%%###**#%@@@@@@*===================*@@@@@@@#**###%%%%%%@@@%#%@@@@@@@@@@@%@@@
// @@@%@@@@@@@@@@@%%#@@@@%%%%####****#@@@@@@@%+===========*@@@@@@@@#****####%%%%@@@@#%@@@@@@@@@@@@%@@@@
// @@@@%%@@@@@@@@@@@%##@@@@%%%%#####*****#%@@@@@@@%##%@@@@@@@@%#*****#####%%%%@@@@##%@@@@@@@@@@@@%@@@@@
// @@@@@%%@@@@@@@@@@@@%##@@@@%%%%%######*******###%%%%%###*******######%%%%%@@@@##%@@@@@@@@@@@@%%@@@@@@
// @@@@@@%%@@@@@@@@@@@@@%##@@@@@%%%%%%########******##*****#########%%%%%@@@@@##%@@@@@@@@@@@@@%%@@@@@@@
// @@@@@@@@%%@@@@@@@@@@@@@%%#%@@@@@%%%%%%%#####################%%%%%%%@@@@@%#%%@@@@@@@@@@@@@%%@@@@@@@@@
// @@@@@@@@@%%@@@@@@@@@@@@@@%%##%@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@@%##%%@@@@@@@@@@@@@@%%@@@@@@@@@@
// @@@@@@@@@@@%%@@@@@@@@@@@@@@@%%%#%%@@@@@@@@@%%%%%%%%%%%%%@@@@@@@@@%%#%%%@@@@@@@@@@@@@@@%%@@@@@@@@@@@@
// @@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@%%%##%%@@@@@@@@@@@@@@@@@@@@@%%##%%%@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@%%%%%######%%%######%%%%%@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%@@@@@@@@@@@@@@@@@@@@@@@@

// Telegram: https://t.me/mogcoin20

contract MOG2 is IMOG2, Context, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    uint256 firstBlock;

    uint256 private _tax = 5;
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 10000000000 * 10 ** _decimals;
    string private constant _name = unicode"Mog 2.0";
    string private constant _symbol = unicode"MOG2";

    uint256 public _maxTxAmount = 200000000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 200000000 * 10 ** _decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownable(_msgSender()) {
        _balances[owner()] = _tTotal;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), owner(), _balances[owner()]);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            taxAmount = amount.mul(_tax).div(100);

            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                require(
                    amount <= _maxTxAmount,
                    "$CORN amount exceeds the maxTxAmount."
                );
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "$CORN amount exceeds the maxWalletSize."
                );
                if (firstBlock + 3 > block.number) {
                    require(!isContract(to));
                }
            }

            if (to != uniswapV2Pair && !_isExcludedFromFee[to])
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "$CORN amount exceeds the maxWalletSize."
                );

            if (to == uniswapV2Pair && from != address(this))
                taxAmount = amount.mul(_tax).div(100);
        }

        if (taxAmount > 0) {
            _balances[owner()] = _balances[owner()].add(taxAmount);
            emit Transfer(from, owner(), taxAmount);
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        emit MOGMaxTxAmountUpdated(_tTotal);

        _tax = 0;
        emit MOGTaxReducedToZero();
    }

    function conify() external onlyOwner {
        require(!tradingOpen, "$MOG2 trading is already open");
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
        firstBlock = block.number;
    }

    receive() external payable {}
}

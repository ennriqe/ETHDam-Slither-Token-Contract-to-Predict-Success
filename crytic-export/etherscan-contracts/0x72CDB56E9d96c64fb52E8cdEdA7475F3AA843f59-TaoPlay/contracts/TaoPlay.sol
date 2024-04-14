
// Website: https://taoplay.io/
// X: https://x.com/TAO_Play
// Telegram: https://t.me/TAO_Play
// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "./LPDiv.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract TaoPlay is ERC20, Ownable {
    uint256 SUPPLY = 20_000_000 * 10 ** 18;

    IUniswapRouter public router;
    address public pair;

    bool private swapping;
    bool public swapEnabled;
    bool public claimEnabled = true;
    bool public tradingEnabled;
    uint public timeAntiBot;

    TaoPlayDividendTracker public dividendTracker;

    address public marketingWallet;

    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    struct Taxes {
        uint256 shareHolder;
        uint256 marketing;
    }

    Taxes public buyTaxes = Taxes(1, 4);
    Taxes public sellTaxes = Taxes(1, 4);

    uint256 public totalBuyTax = 5;
    uint256 public totalSellTax = 5;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    ///////////////
    //   Events  //
    ///////////////

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor(address _marketing) ERC20("TAOPlay", "TAOP") {
        dividendTracker = new TaoPlayDividendTracker();
        setMarketingWallet(_marketing);

        IUniswapRouter _router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;
        pair = _pair;
        setSwapTokensAtAmount(60000); //0.3%

        _setAutomatedMarketMakerPair(_pair, true);

        dividendTracker.updateLP_Token(address(this));

        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(0xdead), true);
        dividendTracker.excludeFromDividends(address(_router), true);

        excludeFromMaxWallet(address(_pair), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(_router), true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        swapEnabled = true;
        maxWallet = SUPPLY;
        _mint(owner(), SUPPLY);
    }

    receive() external payable {}

    function updateDividendTracker(address newAddress) public onlyOwner {
        TaoPlayDividendTracker newDividendTracker = TaoPlayDividendTracker(
            payable(newAddress)
        );
        newDividendTracker.excludeFromDividends(
            address(newDividendTracker),
            true
        );
        newDividendTracker.excludeFromDividends(address(this), true);
        newDividendTracker.excludeFromDividends(owner(), true);
        newDividendTracker.excludeFromDividends(address(router), true);
        dividendTracker = newDividendTracker;
    }

    /// @notice Manual claim the dividends
    function claim() external {
        require(claimEnabled, "Claim not enabled");
        dividendTracker.processAccount(payable(msg.sender));
    }


    function updateMaxWalletAmount(uint256 newNum) public onlyOwner {
        require(newNum >= 200_000, "Cannot set maxWallet lower than 1%");
        maxWallet = newNum * 10**18;
    }

    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount * 10**18;
    }

    function excludeFromMaxWallet(address account, bool excluded)
    public
    onlyOwner
    {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    /// @notice Withdraw tokens sent by mistake.
    /// @param tokenAddress The address of the token to withdraw
    function rescueETH20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    /// @notice Send remaining ETH to dev
    /// @dev It will send all ETH to dev
    function forceSend() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        (bool success, ) = payable(marketingWallet).call{value: ETHbalance}("");
        require(success);
    }

    function trackerRescueTokens(address tokenAddress) external {
        require(msg.sender == marketingWallet, "only marketing wallet!");
        dividendTracker.trackerRescueTokens(msg.sender, tokenAddress);
    }

    function updateRouter(address newRouter) external onlyOwner {
        router = IUniswapRouter(newRouter);
    }

    /////////////////////////////////
    // Exclude / Include functions //
    /////////////////////////////////

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    /// @dev "true" to exlcude, "false" to include
    function excludeFromDividends(address account, bool value)
    public
    onlyOwner
    {
        dividendTracker.excludeFromDividends(account, value);
    }

    function setMarketingWallet(address newWallet) public onlyOwner {
        marketingWallet = newWallet;
    }

    function setBuyTaxes(uint256 _liquidity, uint256 _dev) external onlyOwner {
        require(_liquidity + _dev<= 20, "Fee must be <= 20%");
        buyTaxes = Taxes(_liquidity, _dev);
        totalBuyTax = _liquidity + _dev;
    }

    function setSellTaxes(uint256 _liquidity, uint256 _dev) external onlyOwner {
        require(_liquidity + _dev <= 20, "Fee must be <= 20%");
        sellTaxes = Taxes(_liquidity, _dev);
        totalSellTax = _liquidity + _dev;
    }

    /// @notice Enable or disable internal swaps
    /// @dev Set "true" to enable internal swaps for liquidity, treasury and dividends
    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function activateTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
        maxWallet = SUPPLY / 50; //2% total
        timeAntiBot = block.timestamp + 5 minutes;
    }

    function setClaimEnabled(bool state) external onlyOwner {
        claimEnabled = state;
    }

    function setLP_Token(address _lpToken) external onlyOwner {
        dividendTracker.updateLP_Token(_lpToken);
    }

    /// @dev Set new pairs created due to listing in new DEX
    function setAutomatedMarketMakerPair(address newPair, bool value)
    external
    onlyOwner
    {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(
            automatedMarketMakerPairs[newPair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[newPair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(newPair, true);
        }

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

    //////////////////////
    // Getter Functions //
    //////////////////////

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account)
    public
    view
    returns (uint256, uint256)
    {
        return (dividendTracker.withdrawableDividendOf(account), dividendTracker.withdrawableEthDividendOf(account));
    }

    function dividendTokenBalanceOf(address account)
    public
    view
    returns (uint256)
    {
        return dividendTracker.balanceOf(account);
    }

    function getAccountInfo(address account)
    external
    view
    returns (
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        return dividendTracker.getAccount(account);
    }

    ////////////////////////
    // Transfer Functions //
    ////////////////////////

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (
            !_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping
        ) {
            require(tradingEnabled, "Trading not active");
            
            if (!_isExcludedFromMaxWallet[to] && block.timestamp <= timeAntiBot) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Unable to exceed Max Wallet"
                );
            }
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount && !automatedMarketMakerPairs[from];

        if (
            canSwap &&
            !swapping &&
            swapEnabled
        ) {
            swapping = true;
            swapAndLiquify(balanceOf(address(this)));
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (!automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from])
            takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            if (automatedMarketMakerPairs[to])
                feeAmt = (amount * totalSellTax) / 100;
            else if (automatedMarketMakerPairs[from])
                feeAmt = (amount * totalBuyTax) / 100;

            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
        }
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 dividends = ((tokens * sellTaxes.shareHolder) / totalSellTax);
        uint256 toSwapForETH = (tokens * sellTaxes.marketing) / totalSellTax;

        swapTokensForETH(toSwapForETH);

        // Send ETH to dev
        uint256 devAmt = address(this).balance;

        if (devAmt > 0) {
            (bool success, ) = payable(marketingWallet).call{value: devAmt}("");
            require(success, "Failed to send ETH to dev wallet");
        }
        //Send Token to dividends
        if (dividends > 0) {
            super._transfer(address(this), address(dividendTracker), dividends);
            dividendTracker.distributeLPDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }

    // transfers LP from the owners wallet to holders // must approve this contract, on pair contract before calling
    function ManualLiquidityDistribution(uint256 amount) public onlyOwner {
        bool success = IERC20(pair).transferFrom(
            msg.sender,
            address(dividendTracker),
            amount
        );
        if (success) {
            dividendTracker.distributeLPDividends(amount);
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
}

contract TaoPlayDividendTracker is Ownable, DividendPayingToken {
    struct AccountInfo {
        address account;
        uint256 withdrawableDividends;
        uint256 withdrawableEthDividendOf;
        uint256 totalDividends;
        uint256 lastClaimTime;
    }

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    event ExcludeFromDividends(address indexed account, bool value);
    event Claim(address indexed account, uint256 amount);

    constructor()
    DividendPayingToken("TaoPlay_Dividend_Tracker", "TaoPlay_Dividend_Tracker")
    {}

    function trackerRescueTokens(address recipient, address tokenAddress)
    external
    onlyOwner
    {
        IERC20(tokenAddress).transfer(
            recipient,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function updateLP_Token(address _lpToken) external onlyOwner {
        LP_Token = _lpToken;
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "TaoPlay_Dividend_Tracker: No transfers allowed");
    }

    function excludeFromDividends(address account, bool value)
    external
    onlyOwner
    {
        require(excludedFromDividends[account] != value);
        excludedFromDividends[account] = value;
        if (value == true) {
            _setBalance(account, 0);
        } else {
            _setBalance(account, balanceOf(account));
        }
        emit ExcludeFromDividends(account, value);
    }

    function getAccount(address account)
    public
    view
    returns (
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        AccountInfo memory info;
        info.account = account;
        info.withdrawableDividends = withdrawableDividendOf(account);
        info.withdrawableEthDividendOf = withdrawableEthDividendOf(account);
        info.totalDividends = accumulativeDividendOf(account);
        info.lastClaimTime = lastClaimTimes[account];
        return (
            info.account,
            info.withdrawableDividends,
            info.withdrawableEthDividendOf,
            info.totalDividends,
            info.lastClaimTime,
            totalDividendsWithdrawn,
            totalEthDividendsWithdrawn
        );
    }

    function setBalance(address account, uint256 newBalance)
    external
    onlyOwner
    {
        if (excludedFromDividends[account]) {
            return;
        }
        _setBalance(account, newBalance);
    }

    function processAccount(address payable account)
    external
    onlyOwner
    returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount);
            return true;
        }
        return false;
    }

}
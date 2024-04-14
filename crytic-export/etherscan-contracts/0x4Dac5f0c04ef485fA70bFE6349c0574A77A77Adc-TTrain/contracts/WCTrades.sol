//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "hardhat/console.sol";

interface IDEXFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IDEXRouter {
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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract TTrain is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    uint256 constant NUMERATOR = 1000;
    uint256 public teamTaxRate;
    uint256 public devTaxRate;
    uint256 public airdropTaxRate;
    uint256 public tokensTXLimit;

    // uint256 private tokenEndingNumber;

    IDEXRouter _dexRouter;
    address public dexRouterAddress;
    address public _dexPair;

    mapping(address => bool) public isExemptedFromTax;
    mapping(address => bool) public isDistributorAddress;
    mapping(address => bool) public blacklisted;

    address public MARKETING_WALLET;
    address public DEVELOPMENT_WALLET;
    address public AIRDROP_WALLET;
    uint256 public MAX_WALLET_SIZE;
    bool public isTradingEnabled;

    // bool private isTokenEndingNumberEnabled;

    event TaxReceiversUpdated(address MARKETING_WALLET, address DEVELOPMENT_WALLET ,  address AIRDROP_WALLET);
    event TradingStatusChanged(bool TradeStatus);
    event WalletTokensLimitUpdated(uint256 WalletTokenTxLimit);
    event TokensTXLimit(uint256 TokensLimit);
    event TaxRateSet(uint256 teamTaxRate, uint256 devTaxRate, uint256 airdropTaxRate);
    event BlacklistStatusUpdated(address Address, bool Status);

    modifier onlyDistributor() {
        require(isDistributorAddress[_msgSender()], "Not a Distributor");
        _;
    }

    modifier isNotBlacklisted(address _address) {
        require(!blacklisted[_address], "Address has been Blacklisted");
        _;
    }

    function initialize(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _totalSupply,
        uint256 _teamTaxRate,
        uint256 _devTaxRate,
        uint256 _airdropTaxRate,
        address admin,
        address _teamWallet,
        address _devWallet,
        address _airdropWallet
        // uint256 _endingNumber
    ) external initializer {
        require(
            (_teamTaxRate + _devTaxRate + _airdropTaxRate) <= 200,
            "Taxable: Tax cannot be greater than 20%"
        );

        __ERC20_init(_tokenName, _tokenSymbol);
        __Ownable_init();
        __Pausable_init();
        _mint(admin, _totalSupply);
        setMaxWalletSize((3 * _totalSupply) / 100);
        teamTaxRate = _teamTaxRate;
        devTaxRate = _devTaxRate;
        airdropTaxRate = _airdropTaxRate;
        MARKETING_WALLET = _teamWallet;
        DEVELOPMENT_WALLET = _devWallet;
        AIRDROP_WALLET = _airdropWallet;
        addTaxExemptedAddress(_teamWallet);
        addTaxExemptedAddress(_devWallet);
        addTaxExemptedAddress(_airdropWallet);
        _dexRouter = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // ETH: Uniswap V2 Router
        
        dexRouterAddress = address(_dexRouter);

        //create pair
        _dexPair = IDEXFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );
        IERC20(_dexPair).approve(address(_dexRouter), type(uint256).max);
    }

    function enableTrading() public onlyOwner {
        isTradingEnabled = true;
        emit TradingStatusChanged(true);
    }

    function addToBlacklist(address _address) external onlyOwner {
        if (
            (_address != _dexPair) &&
            (_address != address(_dexRouter)) &&
            (_address != address(this))
        ) blacklisted[_address] = true;
        emit BlacklistStatusUpdated(_address, true);
    }

    function removeFromBlacklist(address _address) external onlyOwner {
        blacklisted[_address] = false;
        emit BlacklistStatusUpdated(_address, false);
    }

    function disableTrading() public onlyOwner {
        isTradingEnabled = false;
        emit TradingStatusChanged(false);
    }

    function addTaxExemptedAddress(address _exemptedAddress) public onlyOwner {
        isExemptedFromTax[_exemptedAddress] = true;
    }

    function addTaxDistributor(address _distributorAddress) public onlyOwner {
        isDistributorAddress[_distributorAddress] = true;
    }

    function removeTaxDistributor(
        address _distributorAddress
    ) public onlyOwner {
        isDistributorAddress[_distributorAddress] = false;
    }

    function removeTaxExemptedAddress(
        address _exemptedAddress
    ) public onlyOwner {
        isExemptedFromTax[_exemptedAddress] = false;
    }

    function setMaxWalletSize(uint256 _maxWalletSize) public onlyOwner {
        MAX_WALLET_SIZE = _maxWalletSize;
        emit WalletTokensLimitUpdated(MAX_WALLET_SIZE);
    }

    function setTaxRate(
        uint256 _teamTaxRate,
        uint256 _devTaxRate,
        uint256 _airdropTaxRate
    ) public onlyOwner whenNotPaused {
        require(
            (_teamTaxRate + _devTaxRate + _airdropTaxRate) < NUMERATOR,
            "Taxable: Tax rate too high"
        );
        require(
            _teamTaxRate + _devTaxRate + _airdropTaxRate<= 200,
            "Taxable: Tax cannot be greater than 20%"
        );
        teamTaxRate = _teamTaxRate;
        devTaxRate = _devTaxRate;
        airdropTaxRate = _airdropTaxRate;

        emit TaxRateSet(teamTaxRate, devTaxRate, airdropTaxRate);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setTransactionLimit(
        uint256 _tokensTXLimit
    ) public onlyOwner whenNotPaused {
        tokensTXLimit = _tokensTXLimit;
        emit TokensTXLimit(tokensTXLimit);
    }

    function getTransactionLimit() public view returns (uint256) {
        return tokensTXLimit;
    }

    function getTaxRate() public view returns (uint256, uint256, uint256) {
        return (teamTaxRate, devTaxRate , airdropTaxRate);
    }

     function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setTaxReceiver(
        address _teamWallet,
        address _devWallet,
        address _airdropWallet
    ) external onlyOwner whenNotPaused {
        console.log(_teamWallet, _devWallet, _airdropWallet);
        console.log(isContract(_teamWallet),  isContract(_devWallet) , isContract(_airdropWallet));
        require(
            (_teamWallet != address(0) && _devWallet != address(0) && _airdropWallet != address(0)) && 
                (!isContract(_teamWallet) && !isContract(_devWallet) && !isContract(_airdropWallet)),
            "Taxable: Tax reciever cannot be zero Or Contract address"
        );

        MARKETING_WALLET = _teamWallet;
        DEVELOPMENT_WALLET = _devWallet;
        AIRDROP_WALLET = _airdropWallet;

        addTaxExemptedAddress(MARKETING_WALLET);
        addTaxExemptedAddress(DEVELOPMENT_WALLET);
        addTaxExemptedAddress(AIRDROP_WALLET);
        emit TaxReceiversUpdated(MARKETING_WALLET, DEVELOPMENT_WALLET , AIRDROP_WALLET);
    }

    function getTaxRecievers() public view returns (address _MARKETING_WALLET) {
        return (MARKETING_WALLET);
    }

    function getContractETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function distributeTax() public onlyDistributor {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouter.WETH();

        uint256 contractWCTBalance = balanceOf(address(this)); //Swifty Balance
        uint256 initialBalance = address(this).balance; //eth balance
        this.approve(address(_dexRouter), contractWCTBalance);
        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractWCTBalance,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 ethAmount = address(this).balance - initialBalance;
        uint256 totalTaxRate = (ethAmount * 10) / (teamTaxRate + devTaxRate + airdropTaxRate);
        uint256 teamFee = (totalTaxRate * teamTaxRate) / 10;
        uint256 devFee = (totalTaxRate * devTaxRate) / 10;
        uint256 airDropFee = (totalTaxRate * airdropTaxRate) / 10;
        payable(MARKETING_WALLET).transfer(teamFee);
        payable(DEVELOPMENT_WALLET).transfer(devFee);
        payable(AIRDROP_WALLET).transfer(airDropFee);
        console.log("Team Eth Balance: ", MARKETING_WALLET.balance);
        console.log("Dev Eth Balance: ", DEVELOPMENT_WALLET.balance);
        console.log("Airdrop Eth Balance: ", AIRDROP_WALLET.balance);

    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        _transfer(from, to, amount);
        _approve(from, _msgSender(), allowance(from, _msgSender()) - amount);
        return true;
    }

    bool public _transferFlag;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override isNotBlacklisted(from) isNotBlacklisted(to) {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");
            uint taxRate = teamTaxRate + devTaxRate + airdropTaxRate;
            require(
                amount <= tokensTXLimit,
                "TX Limit: Cannot transfer more than tokensTXLimit"
            );
            //While Trading
            // user wantes: eth => token --> BUY
            if (
                from == _dexPair &&
                !isExemptedFromTax[to] &&
                to != address(_dexRouter)
            ) {
                require(isTradingEnabled, "Trading is not enabled");
                uint256 amountOfTax = (amount * taxRate) / NUMERATOR;
                super._transfer(from, address(this), amountOfTax);
                super._transfer(from, to, amount - amountOfTax);
            }
            // users wants token => eth or adding Liquidity --> SELL
            else if (
                to == _dexPair &&
                !isExemptedFromTax[from] &&
                from != address(_dexRouter)
            ) {
                uint256 amountOfTax = (amount * taxRate) / NUMERATOR;
                require(isTradingEnabled, "Trading is not enabled");
                super._transfer(from, address(this), amountOfTax);
                super._transfer(from, to, amount - amountOfTax);
            } 
            else{
                super._transfer(from, to, amount);
            }
        }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override whenNotPaused  isNotBlacklisted(from) isNotBlacklisted(to) {}

    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }

    fallback() external payable {}

    receive() external payable {}
}

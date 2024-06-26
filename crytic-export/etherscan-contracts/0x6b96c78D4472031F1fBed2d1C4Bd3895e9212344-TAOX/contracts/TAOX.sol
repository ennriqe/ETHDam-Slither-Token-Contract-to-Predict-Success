// Website: https://taox.ai
// Twitter: https://x.com/taox_ai
// Telegram: https://t.me/taox_ai

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/ITAOXDividendTracker.sol";
import "./interfaces/IUniswapV2Factory.sol";

contract TAOX is Ownable, ERC20 {
    error MaxTxAmountExceeded();
    error MaxWalletAmountExceeded();
    error NotAuthorized();

    event OpenTrading();
    event DisableLimits();
    event UpdateMarketingWL(address _marketingWallet);
    event UpdateTreasuryWL(address _treasury);
    event SwapBack(uint256 amount);
    event UpdateSwapTokenAt(uint256 amount);

    ITAOXDividendTracker public dividendTracker;

    IUniswapV2Router02 immutable router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 _totalSupply = 100_000_000 * 10 ** 18;

    address public pair;

    uint256 TAX = 5;
    uint256 private _initialTax = 30;
    uint256 private _reduceTaxAt = 20;

    uint256 private _buyCount = 0;
    uint256 private _sellCount = 0;

    uint256 private _maxAmount = _totalSupply / 200; // 0.5% of total supply
    uint256 private _maxWallet = _maxAmount; // 0.5% of total supply
    bool private _tradingEnable;

    address public marketingWallet;
    address public treasuryWallet;
    bool public limit = true;
    uint256 public swapTokenAt = _totalSupply / 1000;

    mapping(address => bool) private _isExcludedFromFees;

    bool private _swaping = false;

    modifier onSwap() {
        _swaping = true;
        _;
        _swaping = false;
    }

    constructor(
        address _dividendTracker,
        address _treasury
    ) ERC20("TAOx", "TAOx") {
        marketingWallet = _msgSender();
        treasuryWallet = _treasury;
        pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        dividendTracker = ITAOXDividendTracker(_dividendTracker);
        dividendTracker.setup(address(router), pair);
        _isExcludedFromFees[_msgSender()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(router)] = true;
        _isExcludedFromFees[address(dividendTracker)] = true;
        _mint(_msgSender(), _totalSupply);
        _approve(_msgSender(), address(router), type(uint256).max);
    }

    receive() external payable {}

    function setSwapTokenAt(uint256 value) external onlyOwner {
        require(
            value <= _totalSupply / 50,
            "Value must be less than or equal to SUPPLY / 50"
        );
        swapTokenAt = value;
        emit UpdateSwapTokenAt(value);
    }

    function openTrading() external onlyOwner {
        _tradingEnable = true;
        emit OpenTrading();
    }

    function getIsExcludedFromFees(
        address _address
    ) external view returns (bool) {
        return _isExcludedFromFees[_address];
    }

    function excludedFromFees(
        address _address,
        bool _value
    ) external onlyOwner {
        _isExcludedFromFees[_address] = _value;
    }

    function disableLimits() external onlyOwner {
        require(limit, "Limits already removed");
        limit = false;
        _maxWallet = _totalSupply;
        _maxAmount = _totalSupply;
        emit DisableLimits();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (
            _isExcludedFromFees[from] ||
            _isExcludedFromFees[to] ||
            (to != pair && from != pair) ||
            _swaping
        ) {
            super._transfer(from, to, amount);
            try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
            try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}
            return;
        }

        require(_tradingEnable, "Trading is not open");

        if (limit) {
            if ((from == pair || to == pair) && amount > _maxAmount) {
                revert MaxTxAmountExceeded();
            }
            if (to != pair && balanceOf(to) + amount > _maxWallet) {
                revert MaxWalletAmountExceeded();
            }
        }

        uint256 _totalFees = (amount * TAX) / 100;

        if (to == pair) {
            _sellCount += 1;
            _totalFees =
                (amount *
                    (_sellCount > (_reduceTaxAt / 2) ? TAX : _initialTax)) /
                100;

            if (balanceOf(address(this)) >= swapTokenAt) {
                swapBack();
            }
        }

        if (from == pair) {
            _buyCount += 1;
            _totalFees =
                (amount * (_buyCount > _reduceTaxAt ? TAX : _initialTax)) /
                100;
        }

        if (_totalFees > 0) {
            super._transfer(from, address(this), _totalFees);
            amount = amount - _totalFees;
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}
    }

    function swapBack() public onSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), swapTokenAt);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapTokenAt,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 balance = address(this).balance;

        if (balance > 0) {
            uint256 marketingAmount = balance / 2;
            uint256 treasuryAmount = balance - marketingAmount;

            (bool sent, ) = payable(marketingWallet).call{
                value: marketingAmount
            }("");
            require(sent, "Failed to send Ether to marketing wallet");

            (sent, ) = payable(treasuryWallet).call{value: treasuryAmount}("");

            require(sent, "Failed to send Ether to treasury wallet");
        }

        emit SwapBack(swapTokenAt);
    }

    function updateDividendTracker(address newAddress) external onlyOwner {
        require(
            newAddress != address(dividendTracker),
            "The dividend tracker already has that address"
        );

        ITAOXDividendTracker newDividendTracker = ITAOXDividendTracker(
            newAddress
        );

        newDividendTracker.setup(address(router), pair);

        dividendTracker = newDividendTracker;
    }

    function setMarketingWL(address _marketingWallet) external {
        if (_msgSender() != owner() && _msgSender() != marketingWallet) {
            revert NotAuthorized();
        }
        marketingWallet = _marketingWallet;
        emit UpdateMarketingWL(_marketingWallet);
    }

    function setTreasuryWL(address _treasury) external {
        if (_msgSender() != owner() && _msgSender() != marketingWallet) {
            revert NotAuthorized();
        }
        treasuryWallet = _treasury;
        emit UpdateTreasuryWL(_treasury);
    }
}

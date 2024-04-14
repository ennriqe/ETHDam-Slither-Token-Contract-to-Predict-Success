/*

LIQAI, where our mission extends beyond providing tools; we're reshaping how developers, blockchain technology, and investors interact. By simplifying smart contract technology, $LIQAI breaks down many barriers to adoption. With our Market Maker Tools, we're ushering in a new era of blockchain innovation, transcending traditional liquidity management to propel projects into vibrant market engagement and expansion.

Website: https://liqai.io
x (Twitter): https://twitter.com/intelliquid
Telegram: https://t.me/liqaiportal
Whitepaper: https://gitbook.liqai.io
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./ERC20.sol";

contract IntelLiquid is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bool private swapping;

    address private devWallet;

    uint256 public maxTransaction;
    uint256 public maxWallet;
    uint256 public swapTokensAtAmount;

    bool public limitsInEffect = true;
    bool public tradingEnabled = false;
    bool public swapEnabled = false;

    uint256 public launchBlockNumber;

    uint256 public buyFees;
    uint256 public sellFees;

    uint256 public divisor = 10_000;

    uint256 private _maxSwapableTokens;
    uint256 private _swapToEthAfterBuys = 30;
    uint256 private _removeLimitsAt = 60;
    uint256 private _buysCount = 0;

    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public _isExcludedmaxTransaction;

    mapping(address => bool) public automatedMarketMakerPairs;


    constructor(address _devWallet) ERC20("IntelLiquid", "LIQAI", 9) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        automatedMarketMakerPairs[address(uniswapV2Pair)] = true;

        uint256 totalSupply = 100_000 * 10 ** decimals();

        maxTransaction = (totalSupply * 150) / divisor; 
        maxWallet = (totalSupply * 200) / divisor; 
        swapTokensAtAmount = (totalSupply * 50) / divisor;
        _maxSwapableTokens = (totalSupply * 100) / divisor;

        buyFees = 2_900;
        sellFees = 2_900;

        devWallet = _devWallet;
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(0xdead)] = true;

        _isExcludedmaxTransaction[address(_uniswapV2Router)] = true;
        _isExcludedmaxTransaction[address(uniswapV2Pair)] = true;
        _isExcludedmaxTransaction[owner()] = true;
        _isExcludedmaxTransaction[address(this)] = true;
        _isExcludedmaxTransaction[address(0xdead)] = true;

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Token launched");
        tradingEnabled = true;
        launchBlockNumber = block.number;
        swapEnabled = true;
    }

    function removeLimits() internal returns (bool) {
        limitsInEffect = false;
        buyFees = 500;
        sellFees = 500;
        return true;
    }

    function setBuyFees(uint256 _buyFees) public onlyOwner {
        require(_buyFees + sellFees <= 1500, "Fees exceed 15%");
        buyFees = _buyFees;
    }

    function setSellFees(uint256 _sellFees) public onlyOwner {
        require(buyFees + _sellFees <= 1500, "Fees exceed 15%");
        sellFees = _sellFees;
    }

      function setMinSwapTokens(uint256 _swapTokensAtAmount) public onlyOwner {
        swapTokensAtAmount = _swapTokensAtAmount;
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
                if (!tradingEnabled) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedmaxTransaction[to]
                ) {
                    require(
                        amount <= maxTransaction,
                        "Buy transfer amount exceeds the maxTransaction."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedmaxTransaction[from]
                ) {
                    require(
                        amount <= maxTransaction,
                        "Sell transfer amount exceeds the maxTransaction."
                    );
                } else if (!_isExcludedmaxTransaction[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to] &&
            _buysCount > _swapToEthAfterBuys
        ) {
            swapping = true;
            swapBack(min(contractTokenBalance, _maxSwapableTokens));
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellFees > 0) {
                fees = amount.mul(sellFees).div(divisor);
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyFees > 0) {
                fees = amount.mul(buyFees).div(divisor);
                _buysCount++;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);

        if (_buysCount >= _removeLimitsAt && limitsInEffect) {
            removeLimits();
        }
    }

   

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

    function swapBack(uint256 amount) private {
        bool success;

        if (amount == 0) {
            return;
        }

        uint256 amountToSwapForETH = amount;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance;

        (success, ) = address(devWallet).call{value: ethBalance}("");

    }

     function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

     function manualSwap() external {
        require(_msgSender() == devWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if(tokenBalance > 0){
          swapBack(tokenBalance);
        }
    }
}

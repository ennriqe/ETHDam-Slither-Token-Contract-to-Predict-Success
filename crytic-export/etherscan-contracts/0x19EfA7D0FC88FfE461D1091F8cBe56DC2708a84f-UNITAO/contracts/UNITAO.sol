// Website: https://unitao.io
// Docs: https://docs.unitao.io
// Twitter: https://x.com/UNITAO_IO
// Telegram: https://t.me/UNITAO_IO

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract UNITAO is Ownable, ERC20 {
    event RemovedLimits();
    event TradingEnabled();
    event SwapBack(uint256 amount);

    address public uniswapV2Pair;
    IUniswapV2Router02 immutable router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 SUPPLY = 10_000_000 * 10 ** 18;

    uint256 totalFee = 5;
    uint256 maxAmount = SUPPLY / 100;
    uint256 public maxWallet;

    address public marketingWallet;
    address public _TAOFund;

    bool private tradingEnable;
    bool public limitsInEffect = true;
    uint256 public swapAt = SUPPLY / 1000;

    mapping(address => bool) public isExcludedFromFees;

    constructor() ERC20("UNITAO", "UNITAO") {
        marketingWallet = _msgSender();
        address pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        uniswapV2Pair = pair;

        isExcludedFromFees[_msgSender()] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[address(router)] = true;
        _approve(_msgSender(), address(router), type(uint256).max);
        _mint(_msgSender(), SUPPLY);
    }

    function updateSwapAt(uint256 value) external onlyOwner {
        require(
            value <= SUPPLY / 50,
            "Value must be less than or equal to SUPPLY / 50"
        );
        swapAt = value;
    }

    function openTrading() external onlyOwner {
        tradingEnable = true;
        maxWallet = SUPPLY / 100;
        emit TradingEnabled();
    }

    function excludedFromFees(
        address _address,
        bool _value
    ) external onlyOwner {
        isExcludedFromFees[_address] = _value;
    }

    function removeLimits() external onlyOwner {
        require(limitsInEffect, "Limits already removed");
        limitsInEffect = false;
        maxWallet = SUPPLY;
        emit RemovedLimits();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (
            isExcludedFromFees[from] ||
            isExcludedFromFees[to] ||
            (to != uniswapV2Pair && from != uniswapV2Pair) ||
            inSwap
        ) {
            super._transfer(from, to, amount);
            return;
        }

        require(tradingEnable, "Trading is not open");

        if (limitsInEffect) {
            if (from == uniswapV2Pair || to == uniswapV2Pair) {
                require(amount <= maxAmount, "Max Tx Exceeded");
            }
            if (to != uniswapV2Pair) {
                require(
                    balanceOf(to) + amount <= maxWallet,
                    "Max Wallet Exceeded"
                );
            }
        }

        uint256 fees = (amount * totalFee) / 100;

        if (to == uniswapV2Pair && balanceOf(address(this)) >= swapAt) {
            swapBack();
        }

        if (fees > 0) {
            super._transfer(from, address(this), fees);
            amount = amount - fees;
        }
        super._transfer(from, to, amount);
    }

    bool private inSwap = false;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    function swapBack() public swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), swapAt);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAt,
            0,
            path,
            address(this),
            block.timestamp
        );

        emit SwapBack(swapAt);
    }

    function setMarketingWallet(address payable _marketingWallet) external {
        require(_msgSender() == marketingWallet, "Not authorized");
        marketingWallet = _marketingWallet;
    }

    function setTAOFund(address payable __TAOFund) external {
        require(
            _msgSender() == _TAOFund || _msgSender() == owner(),
            "Not authorized"
        );
        _TAOFund = __TAOFund;
    }

    receive() external payable {
        uint256 value = msg.value;
        uint256 amountToTAOFund = (value * 60) / 100; // 60%
        uint256 amountToMarketing = value - amountToTAOFund;

        (bool sent, ) = payable(marketingWallet).call{value: amountToMarketing}(
            ""
        );

        require(sent, "Failed to send Ether");

        (sent, ) = payable(_TAOFund).call{value: amountToTAOFund}("");

        require(sent, "Failed to send Ether");
    }
}

/**
 * @title TAONET is constructed as a unique Parachain, full of promise, and focuses on expanding the capabilities of the Bittensor network.
 * @author dev@taonet.ai
 * Website: https://taonet.ai
 * Twitter: https://twitter.com/taonetai
 */

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV2Router02} from "./IUniswapRouter.sol";
import {IUniswapV2Factory} from "./IUniswapFactory.sol";

contract TAONET is Ownable, ERC20 {
    IUniswapV2Router02 immutable router;
    uint256 constant TOTAL_SUPPLY = 100_000_000 ether;
    uint256 constant TX_FEE = 5;

    uint256 private _maxAmount;
    uint256 private _maxTx;
    bool private _inSwap = false;

    uint256 public swapAmount;
    address public v2Pool;
    address public taxWallet;
    address public devWallet;
    bool public limitsInEffect;
    mapping(address => bool) public isExcludedFromFees;

    constructor(address _taxWallet) ERC20("TaoNet", "TaoNet") {
        taxWallet = _taxWallet;

        devWallet = _msgSender();

        _maxAmount = TOTAL_SUPPLY / 100;

        _maxTx = _maxAmount;

        limitsInEffect = true;

        swapAmount = TOTAL_SUPPLY / 1000;

        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        v2Pool = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        isExcludedFromFees[_msgSender()] = true;

        isExcludedFromFees[address(this)] = true;

        isExcludedFromFees[address(router)] = true;

        _mint(_msgSender(), TOTAL_SUPPLY);
    }

    function updateSwapAmount(uint256 value) external onlyOwner {
        require(
            value <= TOTAL_SUPPLY / 50,
            "Value must be less than or equal to SUPPLY / 50"
        );
        swapAmount = value;
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
        _maxTx = TOTAL_SUPPLY;
        _maxAmount = TOTAL_SUPPLY;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (
            isExcludedFromFees[from] ||
            isExcludedFromFees[to] ||
            (to != v2Pool && from != v2Pool) ||
            _inSwap
        ) {
            super._transfer(from, to, amount);
            return;
        }

        if (limitsInEffect) {
            if (from == v2Pool || to == v2Pool) {
                require(amount <= _maxAmount, "Max Tx Exceeded");
            }
            if (to != v2Pool) {
                require(
                    balanceOf(to) + amount <= _maxTx,
                    "Max Wallet Exceeded"
                );
            }
        }

        uint256 fees = (amount * TX_FEE) / 100;

        if (to == v2Pool && balanceOf(address(this)) >= swapAmount) {
            _inSwap = true;
            _swapTokenForETH();
            _inSwap = false;
        }

        if (fees > 0) {
            super._transfer(from, address(this), fees);
            amount = amount - fees;
        }
        super._transfer(from, to, amount);
    }

    function _swapTokenForETH() private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), swapAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 _balance = address(this).balance;
        if (_balance > 0) {
            uint256 amount1 = (_balance * 80) / 100;
            uint256 amount2 = _balance - amount1;

            (bool sent, ) = payable(taxWallet).call{value: amount1}("");

            require(sent, "Failed to send Ether");

            (sent, ) = payable(devWallet).call{value: amount2}("");

            require(sent, "Failed to send Ether");
        }
    }

    function updateTaxWallet(address _newAddress) external {
        require(
            _msgSender() == taxWallet || _msgSender() == owner(),
            "Not authorized"
        );
        taxWallet = _newAddress;
    }

    function updateDevWallet(address _newAddress) external {
        require(
            _msgSender() == devWallet || _msgSender() == owner(),
            "Not authorized"
        );
        devWallet = _newAddress;
    }

    receive() external payable {}
}

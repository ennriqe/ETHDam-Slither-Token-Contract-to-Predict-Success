/*
// Escape Room > $ESC < t.me/escaperoomgame

>>>

You awaken to blackness and the sound of an old, antique clock ticking. Out of the darkness, a frail voice croaks through a distorted tannoy system.

''Wake up. It’s time.''

>>>
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Erc20.sol";
import "./PoolCreatableErc20.sol";
import "../lib/Ownable.sol";

contract EscapeRoom is PoolCreatableErc20, Ownable, ReentrancyGuard {
    uint256 constant _startTotalSupply = 86400 * (10 ** _decimals);
    uint256 constant _startMaxBuyCount = (_startTotalSupply * 5) / 10000;
    uint256 constant _addMaxBuyPercentPerSec = 5; // 100%=_addMaxBuyPrecesion add 0.005%/second
    uint256 constant _addMaxBuyPrecesion = 100000;
    uint256 public taxBuy = 250;
    uint256 public taxSell = 250;
    uint256 public constant taxPrecesion = 1000;
    uint256 public sawShare = 500;
    uint256 public burnShare = 0;
    uint256 constant sharePrecesion = 1000;
    address public sawAddress;
    uint256 constant _transferZeroTaxSeconds = 1000; // zero tax transfer time
    address _deployer;
    uint256 constant sellTimer = 86400;
    uint256 constant transferTimer = 86400;
    address public gameAddress;

    constructor() PoolCreatableErc20("Escape Room", "ESC", msg.sender) { 
        _deployer = msg.sender;
        sawAddress = msg.sender;
    }

    modifier onlySaw() {
        require(msg.sender == sawAddress, "only for saw");
        _;
    }

    receive() external payable {
        uint256 toSaw = (msg.value * sawShare) / sharePrecesion;
        uint256 toGame = msg.value - toSaw;
        if (toSaw > 0) sendEth(sawAddress, toSaw);
        if (toGame > 0) {
            if (gameAddress != address(0)) sendEth(gameAddress, toGame);
            else sendEth(sawAddress, toGame);
        }
    }

    function setSawShare(uint256 newSawShare) external onlySaw {
        require(newSawShare <= sharePrecesion, "bad saw share");
        sawShare = newSawShare;
    }

    function setSaw(address newSawAddress) external onlySaw {
        sawAddress = newSawAddress;
    }

    function setBurnShare(uint256 newBurnShare) external onlyOwner {
        require(newBurnShare <= sharePrecesion, "bad burn share");
        burnShare = newBurnShare;
    }

    function setTax(uint256 taxBuy_, uint256 taxSell_) external onlyOwner {
        require(taxBuy_ <= taxBuy);
        require(taxSell_ <= taxSell);
        taxBuy = taxBuy_;
        taxSell = taxSell_;
    }

    function setGame(address newGameAddress) external onlyOwner {
        gameAddress = newGameAddress;
    }

    function sendEth(address to, uint256 value) private nonReentrant {
        (bool sent, ) = to.call{value: value}("");
        require(sent, "Failed to send Ether");
    }

    modifier maxBuyLimit(uint256 amount) {
        require(amount <= maxBuy(), "max buy limit");
        _;
    }

    function createPairCount() internal pure override returns (uint256) {
        return _startTotalSupply;
    }

    function maxBuy() public view returns (uint256) {
        if (!isStarted()) return _startTotalSupply;
        uint256 count = _startMaxBuyCount +
            (_startTotalSupply *
                (block.timestamp - _startTime) *
                _addMaxBuyPercentPerSec) /
            _addMaxBuyPrecesion;
        if (count > _startTotalSupply) count = _startTotalSupply;
        return count;
    }

    function transferTax() public view returns (uint256) {
        if (!isStarted()) return 0;
        uint256 deltaTime = block.timestamp - _startTime;
        if (deltaTime >= _transferZeroTaxSeconds) return 0;
        return
            (taxPrecesion * (_transferZeroTaxSeconds - deltaTime)) /
            _transferZeroTaxSeconds;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // allow burning
        if (to == address(0)) {
            _burn(from, amount);
            return;
        }

        // system transfers
        if (
            from == address(this) ||
            from == _deployer ||
            to == _deployer
        ) {
            super._transfer(from, to, amount);
            return;
        }

        // transfers with fee
        if (_feeLocked) {
            super._transfer(from, to, amount);
            return;
        } else {
            if (from == _pair) {
                buy(to, amount);
                return;
            } else if (to == _pair) {
                sell(from, amount);
                return;
            } else transferWithFee(from, to, amount);
        }
    }

    function buy(
        address to,
        uint256 amount
    ) private maxBuyLimit(amount) lockFee {
        uint256 tax = (amount * taxBuy) / taxPrecesion;
        uint256 burn = (amount * burnShare) / sharePrecesion;
        if (burn > 0) _burn(_pair, burn);
        if (tax > 0) super._transfer(_pair, address(this), tax);
        super._transfer(_pair, to, amount - tax - burn);
    }

    function sell(address from, uint256 amount) private lockFee {
        _sellTokens();
        uint256 tax = (amount * taxSell) / taxPrecesion;
        uint256 burn = (amount * burnShare) / sharePrecesion;
        if (burn > 0) _burn(from, burn);
        if (tax > 0) super._transfer(from, address(this), tax);
        super._transfer(from, _pair, amount - tax - burn);
    }

    function _sellTokens() private {
        uint256 sellCount = balanceOf(address(this));
        uint256 maxSwapCount = sellCount * 2;
        if (sellCount > maxSwapCount) sellCount = maxSwapCount;
        _sellTokens(sellCount, address(this));
    }

    function transferWithFee(
        address from,
        address to,
        uint256 amount
    ) private lockFee {
        uint256 tax = (amount * transferTax()) / taxPrecesion;
        if (tax > 0) _burn(from, tax);
        super._transfer(from, to, amount - tax);
    }

    function burnCount() public view returns (uint256) {
        return _startTotalSupply - totalSupply();
    }
}

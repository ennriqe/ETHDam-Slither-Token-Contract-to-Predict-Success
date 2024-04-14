// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./Erc20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../lib/Ownable.sol";

abstract contract PoolCreatableErc20 is ERC20 {
    IUniswapV2Router02 constant uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address internal _pair;
    uint256 internal _startTime;
    bool internal _feeLocked;
    address immutable _pairCreator;

    constructor(
        string memory name_,
        string memory symbol_,
        address pairCreator
    ) ERC20(name_, symbol_) {
        _pairCreator = pairCreator;
    }

    modifier lockFee() {
        _feeLocked = true;
        _;
        _feeLocked = false;
    }

    function createPair() external payable {
        require(msg.sender == _pairCreator);
        _pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _mint(address(this), createPairCount());
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            createPairCount(),
            0,
            0,
            msg.sender,
            block.timestamp
        );
        _startTime = block.timestamp;
    }

    function isStarted() internal view returns (bool) {
        return _pair != address(0);
    }

    function createPairCount() internal pure virtual returns (uint256);

    function _sellTokens(uint256 tokenAmount, address to) internal lockFee {
        if (tokenAmount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            to,
            block.timestamp
        );
    }

    function pair() external view returns (address) {
        return _pair;
    }
}

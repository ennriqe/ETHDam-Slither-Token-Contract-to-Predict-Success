// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./math/SafeMath.sol";
import "./uniswap/IUniswapV2Factory.sol";
import "./uniswap/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICORN is IERC20 {
    event CornMaxTxAmountUpdated(uint value);
    event CornTaxReducedToZero();
}

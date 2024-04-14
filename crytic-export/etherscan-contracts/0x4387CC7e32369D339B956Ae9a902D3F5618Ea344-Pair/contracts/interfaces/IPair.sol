// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IERC20 } from "./IERC20.sol";

interface IPair is IERC20 {
    struct Fees {
        uint amount0;
        uint amount1;
    }
    function collect(address, address) external;
    function feeBalances(address) external view returns (Fees memory);
    function initialize(address factory, address token0, address token1, address _feeTaker, address _takeFeeIn) external;
    function amountIn(address output, uint _amountOut, address caller) external view returns (uint _amountIn);
    function amountOut(address input, uint _amountIn, address caller) external view returns (uint _amountOut);
    function swap(
        address to,
        address caller,
        address factory
    ) external returns (uint);
    function borrow(address to, uint _amountOut, bool isToken0, bytes calldata data) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (
        uint112 _reserve0, 
        uint112 _reserve1, 
        uint32 _blockTimestampLast
    );
    function token0() external view returns (address);
    function token1() external view returns (address);
    function factory() external view returns (address);
}
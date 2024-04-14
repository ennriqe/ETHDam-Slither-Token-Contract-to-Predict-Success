// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


interface IGenerator {
    struct Info {
        address owner;
        uint16 burnFee;
        address burnToken;
        uint16 teamFee;
        address teamAddress;
        uint16 lpFee;
        address referrer;
        uint16 referFee;
        uint16 labFee;
    }
    function allowLoans() external view returns (bool);
    function isPair(address) external view returns (bool);
    function borrowFee() external view returns (uint16);
    function factoryInfo(address) external view returns (Info memory);
    function pairFees(address pair) external view returns (Info memory);
    function LAB_FEE() external view returns (uint16);
    function FEE_DENOMINATOR() external view returns (uint16);
    function stables(address) external view returns (bool);
    function pairs(address factory, address token0, address token1) external view returns (address);
    function getPairs(address[] calldata path) external  view returns (address[] memory _pairs);
    function maxSwap2Fee(uint16 f) external view returns (uint16);
    function swapInternal(
        address[] calldata _pairs,
        address caller,
        address to
    ) external returns (uint256 amountOut);
    function WRAPPED_ETH() external view returns (address);
    function createPair(
        address tokenA, 
        address tokenB
    ) external returns (address pair);
     function createSwap2Pair(
        address tokenA, 
        address tokenB,
        address feeTaker,
        address takeFeeIn
    ) external returns (address pair);
    function createPairWithLiquidity(
        address tokenA, 
        address tokenB,
        uint amountA,
        uint amountB,
        address to,
        address feeTaker,
        address takeFeeIn
    ) external returns (address pair);
    function isFactory(address) external returns (bool);
    function tokens(address) external returns (address[] memory);
}
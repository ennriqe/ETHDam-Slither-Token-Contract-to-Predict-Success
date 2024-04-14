// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IFactory {
    function router() external view returns (address);
    function initialize(address) external;
    function allPairs(uint) external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address);
    function allPairsLength() external view returns (uint);
    function createPair(
        address tokenA, 
        address tokenB
    ) external returns (address pair);
}
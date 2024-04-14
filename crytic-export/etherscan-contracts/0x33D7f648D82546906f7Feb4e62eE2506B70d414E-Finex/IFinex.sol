// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.24;

interface IFinex {
    function getTokensInCirculation() external view returns (uint256);
    function withdraw(uint256 amount) external;
}
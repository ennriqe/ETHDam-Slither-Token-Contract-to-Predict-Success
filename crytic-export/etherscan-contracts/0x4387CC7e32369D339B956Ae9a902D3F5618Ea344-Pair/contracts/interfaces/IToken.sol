// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IToken {
    function addPair(address pair, address token) external;
    function handleFee() external;
    function getTotalFee(address) external view returns (uint16);
}

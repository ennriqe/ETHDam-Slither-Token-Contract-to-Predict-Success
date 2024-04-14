// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IBorrower {
    function onLoan(address token, uint amount, uint16 fee, bytes calldata data) external;
}
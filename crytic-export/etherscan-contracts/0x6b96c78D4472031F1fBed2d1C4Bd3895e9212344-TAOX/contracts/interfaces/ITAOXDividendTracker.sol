// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

interface ITAOXDividendTracker {
    function setup(address router, address pairt) external;

    function setBalance(address account, uint256 newBalance) external;
}

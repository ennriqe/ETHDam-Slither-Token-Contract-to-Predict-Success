// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

interface ICoreDepositV1 {
    event Deposit(address indexed actor, address[] assetAddresses, uint256[] amounts);

    function deposit(uint256[] calldata amounts, address[] calldata assetAddresses) external payable;
}

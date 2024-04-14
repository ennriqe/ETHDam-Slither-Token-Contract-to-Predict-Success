// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

interface ICoreTransfersNativeV1 {
    /**
     * @dev Emitted when `value` native asset is received by the contract
     */
    event NativeTransfer(address indexed from, uint256 value);

    receive() external payable;
}

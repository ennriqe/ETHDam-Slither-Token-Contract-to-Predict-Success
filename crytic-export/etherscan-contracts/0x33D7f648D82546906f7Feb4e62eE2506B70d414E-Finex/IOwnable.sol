// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.24;

interface IOwnable {
    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
}
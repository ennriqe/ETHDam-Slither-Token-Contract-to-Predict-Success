// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IOperatorRegistry {
    
    error OperatorNotAllowed();

    function isAllowedOperator(address operator, address tokenHolder) external view returns (bool);
}
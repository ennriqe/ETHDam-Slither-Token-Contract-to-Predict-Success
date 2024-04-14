// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;

interface IRegistryContract {
    function getContract(bytes32 name) external view returns (address);
}

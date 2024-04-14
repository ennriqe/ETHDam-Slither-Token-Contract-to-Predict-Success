// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

interface IGlobalGuardian {
    function disable(bytes32 keyHash) external;

    function enable(bytes32 keyHash) external;

    function functionalityIsDisabled(bytes32 keyHash) external view returns (bool);
}

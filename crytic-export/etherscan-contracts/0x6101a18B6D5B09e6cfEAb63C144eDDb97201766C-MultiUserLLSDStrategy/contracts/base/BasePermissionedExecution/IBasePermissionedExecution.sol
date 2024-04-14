// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { ICoreAccessControlV1 } from "../../core/CoreAccessControl/v1/ICoreAccessControlV1.sol";

interface IBasePermissionedExecution is ICoreAccessControlV1 {
    function executeOperation(address target, bytes calldata payload) external payable;
}

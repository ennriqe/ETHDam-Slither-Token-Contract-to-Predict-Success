// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { ICoreAccessControlV1 } from "../../../core/CoreAccessControl/v1/ICoreAccessControlV1.sol";
import { ICoreDepositV1 } from "../../../core/CoreDeposit/v1/ICoreDepositV1.sol";
import { ICoreStopGuardianV1 } from "../../../core/CoreStopGuardian/v1/ICoreStopGuardianV1.sol";
import { ICoreWithdrawV1 } from "../../../core/CoreWithdraw/v1/CoreWithdraw.sol";

// This interface cannot be implemented on BaseTransfers.sol, but it's accurate
// since BaseTransfers.sol only inherits and overrides methods, and does not define
// additional public/external methods.

interface IBaseTransfersV1 is ICoreDepositV1, ICoreWithdrawV1, ICoreAccessControlV1, ICoreStopGuardianV1 {

}

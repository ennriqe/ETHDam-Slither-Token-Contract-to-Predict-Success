// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { ICoreStopGuardianV1 } from "./ICoreStopGuardianV1.sol";

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { StopGuardianEnabled } from "../../libraries/DefinitiveErrors.sol";

abstract contract CoreStopGuardian is ICoreStopGuardianV1, Context {
    bool public STOP_GUARDIAN_ENABLED;

    // recommended for every public/external function
    modifier stopGuarded() {
        if (STOP_GUARDIAN_ENABLED) {
            revert StopGuardianEnabled();
        }

        _;
    }

    function enableStopGuardian() public virtual;

    function disableStopGuardian() public virtual;

    function _enableStopGuardian() internal {
        STOP_GUARDIAN_ENABLED = true;
        emit StopGuardianUpdate(_msgSender(), true);
    }

    function _disableStopGuardian() internal {
        STOP_GUARDIAN_ENABLED = false;
        emit StopGuardianUpdate(_msgSender(), false);
    }
}

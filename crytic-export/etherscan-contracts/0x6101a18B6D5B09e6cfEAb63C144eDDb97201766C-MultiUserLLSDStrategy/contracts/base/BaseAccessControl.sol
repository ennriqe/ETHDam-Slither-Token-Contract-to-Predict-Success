// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { CoreAccessControl, CoreAccessControlConfig } from "../core/CoreAccessControl/v1/CoreAccessControl.sol";
import { CoreStopGuardian } from "../core/CoreStopGuardian/v1/CoreStopGuardian.sol";
import { CoreStopGuardianTrading } from "../core/CoreStopGuardianTrading/v1/CoreStopGuardianTrading.sol";

abstract contract BaseAccessControl is CoreAccessControl, CoreStopGuardian, CoreStopGuardianTrading {
    /**
     * @dev
     * Modifiers inherited from CoreAccessControl:
     * onlyDefinitive
     * onlyClients
     * onlyWhitelisted
     * onlyClientAdmin
     * onlyDefinitiveAdmin
     *
     * Modifiers inherited from CoreStopGuardian:
     * stopGuarded
     */

    constructor(CoreAccessControlConfig memory coreAccessControlConfig) CoreAccessControl(coreAccessControlConfig) {}

    /**
     * @dev Inherited from CoreStopGuardian
     */
    function enableStopGuardian() public override onlyAdmins {
        return _enableStopGuardian();
    }

    /**
     * @dev Inherited from CoreStopGuardian
     */
    function disableStopGuardian() public override onlyClientAdmin {
        return _disableStopGuardian();
    }

    /**
     * @dev Inherited from CoreStopGuardianTrading
     */

    function disableTrading() public override onlyAdmins {
        return _disableTrading();
    }

    /**
     * @dev Inherited from CoreStopGuardianTrading
     */
    function enableTrading() public override onlyAdmins {
        return _enableTrading();
    }

    /**
     * @dev Inherited from CoreStopGuardianTrading
     */
    function disableWithdrawals() public override onlyClientAdmin {
        return _disableWithdrawals();
    }

    /**
     * @dev Inherited from CoreStopGuardianTrading
     */
    function enableWithdrawals() public override onlyClientAdmin {
        return _enableWithdrawals();
    }
}

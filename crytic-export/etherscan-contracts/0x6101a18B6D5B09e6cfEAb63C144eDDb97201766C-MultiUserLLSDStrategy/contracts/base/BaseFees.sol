// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { BaseAccessControl } from "./BaseAccessControl.sol";
import { CoreFees, CoreFeesConfig } from "../core/CoreFees/v1/CoreFees.sol";
import { DefinitiveAssets, IERC20 } from "../core/libraries/DefinitiveAssets.sol";
import { DefinitiveConstants } from "../core/libraries/DefinitiveConstants.sol";
import { InvalidFeePercent } from "../core/libraries/DefinitiveErrors.sol";

abstract contract BaseFees is BaseAccessControl, CoreFees {
    using DefinitiveAssets for IERC20;

    constructor(CoreFeesConfig memory coreFeesConfig) CoreFees(coreFeesConfig) {}

    function updateFeeAccount(address payable _feeAccount) public override onlyDefinitiveAdmin {
        _updateFeeAccount(_feeAccount);
    }

    function _handleFeesOnAmount(address token, uint256 amount, uint256 feePct) internal returns (uint256 feeAmount) {
        uint256 mMaxFeePCT = DefinitiveConstants.MAX_FEE_PCT;
        if (feePct > mMaxFeePCT) {
            revert InvalidFeePercent();
        }

        feeAmount = (amount * feePct) / mMaxFeePCT;
        if (feeAmount == 0) {
            return feeAmount;
        }

        if (token == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
            DefinitiveAssets.safeTransferETH(FEE_ACCOUNT, feeAmount);
        } else {
            IERC20(token).safeTransfer(FEE_ACCOUNT, feeAmount);
        }
    }
}

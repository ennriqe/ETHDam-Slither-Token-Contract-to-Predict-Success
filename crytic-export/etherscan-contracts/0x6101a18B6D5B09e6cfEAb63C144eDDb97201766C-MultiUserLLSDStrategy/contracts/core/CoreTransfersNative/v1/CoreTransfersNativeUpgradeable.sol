// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { ICoreTransfersNativeV1 } from "./ICoreTransfersNativeV1.sol";

import { DefinitiveAssets, IERC20 } from "../../libraries/DefinitiveAssets.sol";
import { DefinitiveConstants } from "../../libraries/DefinitiveConstants.sol";
import { InvalidInputs, InvalidMsgValue } from "../../libraries/DefinitiveErrors.sol";

/// @notice Copied from CoreTransfersNative/v1/CoreTransfersNative.sol
abstract contract CoreTransfersNativeUpgradeable is ICoreTransfersNativeV1, ContextUpgradeable {
    using DefinitiveAssets for IERC20;

    /**
     * @notice Allows contract to receive native assets
     */
    receive() external payable virtual {
        emit NativeTransfer(_msgSender(), msg.value);
    }

    function __CoreTransfersNative_init() internal onlyInitializing {
        __Context_init();
        __CoreTransfersNative_init_unchained();
    }

    function __CoreTransfersNative_init_unchained() internal onlyInitializing {}

    function _depositNativeAndERC20(DefinitiveConstants.Assets memory depositAssets) internal virtual {
        uint256 assetAddressesLength = depositAssets.addresses.length;
        if (depositAssets.amounts.length != assetAddressesLength) {
            revert InvalidInputs();
        }

        uint256 nativeAssetIndex = type(uint256).max;

        for (uint256 i; i < assetAddressesLength; ) {
            if (depositAssets.addresses[i] == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
                nativeAssetIndex = i;
                unchecked {
                    ++i;
                }
                continue;
            }
            // ERC20 tokens
            IERC20(depositAssets.addresses[i]).safeTransferFrom(_msgSender(), address(this), depositAssets.amounts[i]);
            unchecked {
                ++i;
            }
        }
        // Revert if NATIVE_ASSET_ADDRESS is not in assetAddresses and msg.value is not zero
        if (nativeAssetIndex == type(uint256).max && msg.value != 0) {
            revert InvalidMsgValue();
        }

        // Revert if depositing native asset and amount != msg.value
        if (nativeAssetIndex != type(uint256).max && msg.value != depositAssets.amounts[nativeAssetIndex]) {
            revert InvalidMsgValue();
        }
    }
}

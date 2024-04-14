// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { DefinitiveAssets } from "../../core/libraries/DefinitiveAssets.sol";
import { IWETH9 } from "../../vendor/interfaces/IWETH9.sol";

abstract contract BaseNativeWrapperUpgradeable is Initializable {
    address payable public WRAPPED_NATIVE_ASSET_ADDRESS;

    function __BaseNativeWrapper_init(address wrappedNativeAssetAddress) internal onlyInitializing {
        __BaseNativeWrapper_init_unchained(wrappedNativeAssetAddress);
    }

    function __BaseNativeWrapper_init_unchained(address wrappedNativeAssetAddress) internal onlyInitializing {
        WRAPPED_NATIVE_ASSET_ADDRESS = payable(wrappedNativeAssetAddress);
    }

    function _wrap(uint256 amount) internal {
        // slither-disable-next-line arbitrary-send-eth
        IWETH9(WRAPPED_NATIVE_ASSET_ADDRESS).deposit{ value: amount }();
    }

    function _unwrap(uint256 amount) internal {
        IWETH9(WRAPPED_NATIVE_ASSET_ADDRESS).withdraw(amount);
    }

    function _wrapAll() internal {
        return _wrap(address(this).balance);
    }

    function _unwrapAll() internal {
        return _unwrap(DefinitiveAssets.getBalance(WRAPPED_NATIVE_ASSET_ADDRESS));
    }
}

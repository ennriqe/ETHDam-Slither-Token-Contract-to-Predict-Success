// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IPool, StableDebtToken} from "@zerolendxyz/core-v3/contracts/protocol/tokenization/StableDebtToken.sol";

contract StableDebtTokenDisabled is StableDebtToken {
    constructor(IPool pool) StableDebtToken(pool) {
        // Intentionally left blank
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return 4;
    }

    function mint(
        address,
        address,
        uint256,
        uint256
    ) external virtual override onlyPool returns (bool, uint256, uint256) {
        revert("STABLE_BORROWING_DEPRECATED");
    }
}

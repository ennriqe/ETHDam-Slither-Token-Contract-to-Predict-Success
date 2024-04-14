// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import {CopraCommons} from "./CopraCommons.sol";
import {ICopraAccessControlClient} from "./ICopraAccessControlClient.sol";

/// An interface that defines the GMP modules (adapters) that the CopraRouter interacts with.
abstract contract ICopraClient is ICopraAccessControlClient {
    uint256 private immutable DEFAULT_QUORUM;

    constructor(uint256 _defaultQuorum) {
        DEFAULT_QUORUM = _defaultQuorum;
    }

    /// @notice Receives message from GMP(s) through CopraRouter
    /// @param fromGmpIds IDs of the GMPs that sent this message (that reached quorum requirements)
    /// @param fromChainId Source chain (Copra chain ID)
    /// @param fromAddress Source address on source chain
    /// @param payload Routed payload
    function receiveMessage(
        uint8[] calldata fromGmpIds,
        uint256 fromChainId,
        address fromAddress,
        bytes calldata payload
    ) external virtual;

    /// @notice The quorum of messages that the contract expects with a specific message
    function getQuorum(
        CopraCommons.CopraData memory,
        bytes memory
    ) public view virtual returns (uint256) {
        return DEFAULT_QUORUM;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import {CopraCommons} from "./CopraCommons.sol";
import {ICopraAccessControlClient} from "./ICopraAccessControlClient.sol";

/// An interface that defines the GMP modules (adapters) that the CopraRouter interacts with.
/// Should be paired with the ICopraClient abstract smart contract.
interface ICopraTokenClient is ICopraAccessControlClient {
    /// @notice Receives message from GMP(s) through CopraRouter
    /// @param fromGmpIds ID of the GMP that sent this message (that reached quorum requirements)
    /// @param fromChainId Source chain (Copra chain ID)
    /// @param fromAddress Source address on source chain
    /// @param payload Routed payload
    function receiveMessageWithTokens(
        uint8[] memory fromGmpIds,
        uint256 fromChainId,
        address fromAddress,
        bytes calldata payload,
        address token,
        uint256 amount
    ) external;

    /// @notice The quorum of messages that the contract expects with a specific message from the
    ///         token router
    function getQuorum(
        CopraCommons.CopraData memory,
        bytes memory,
        address,
        uint256
    ) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.18;

import {CopraCommons} from "./CopraCommons.sol";
import {IMessageDispatcher} from "./IMessageDispatcher.sol";
import {IMessageExecutor} from "./IMessageExecutor.sol";

abstract contract ICopraRouterEvents is
    CopraCommons,
    IMessageDispatcher,
    IMessageExecutor
{
    event CopraAbstractRouter__MessageIdCreated(
        bytes32 indexed messageId,
        address indexed sender,
        uint256 nonce
    );
    event CopraRouter__ReceivedMessage(
        bytes32 indexed messageId,
        address indexed from,
        uint256 indexed fromChainId,
        address to
    );
    event CopraRouter__MessageDispatched(
        bytes32 indexed messageId,
        address indexed from,
        uint256 indexed toChainId,
        address to,
        bytes data,
        uint8[] gmps,
        uint256[] fees,
        address refundAddress,
        bool retriable
    );
    event CopraRouter__MessageRetried(
        bytes32 indexed messageId,
        address indexed from,
        uint256 indexed toChainId,
        address to,
        bytes data,
        uint8[] gmps,
        uint256[] fees,
        address refundAddress
    );
}

interface ICopraRouter {
    function route(
        uint256 chainId,
        address to,
        bytes memory payload,
        uint8[] memory gmps,
        uint256[] memory fees,
        address refundAddress,
        bool retry
    ) external payable returns (bytes32);

    function routeRetry(
        uint256 chainId,
        address to,
        bytes memory payload,
        uint8[] memory gmp,
        uint256[] memory fees,
        address refundAddress,
        bytes32 messageId,
        uint256 nonce
    ) external payable returns (bytes32);

    function receiveMessage(
        uint256 fromChainId,
        bytes memory CopraPayload
    ) external;
}

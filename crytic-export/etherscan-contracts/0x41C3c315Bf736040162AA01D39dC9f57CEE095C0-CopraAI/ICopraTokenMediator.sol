// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.18;

import {IMessageDispatcher} from "./IMessageDispatcher.sol";
import {IMessageExecutor} from "./IMessageExecutor.sol";

interface ICopraTokenMediator is IMessageDispatcher, IMessageExecutor {
    event CopraTokenMediator__TokensBurnt(
        address from,
        address token,
        uint256 amount
    );
    event CopraTokenMediator__TokensMinted(
        address to,
        address token,
        uint256 amount
    );

    function route(
        uint256 chainId,
        address to,
        bytes memory payload,
        uint8[] memory gmps,
        uint256[] memory fees,
        address refundAddress,
        bool retry,
        address token,
        uint256 tokenAmount
    ) external payable returns (bytes32);

    function routeRetry(
        uint256 chainId,
        address to,
        bytes memory payload,
        uint8[] memory gmp,
        uint256[] memory fees,
        address refundAddress,
        bytes32 messageId,
        uint256 nonce,
        address token,
        uint256 tokenAmount
    ) external payable returns (bytes32);
}

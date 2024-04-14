//SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.19;

interface IProposer {
    function addAllowedProposer(address _proposer) external;

    function removeAllowedProposer(address _proposer) external;

    function propose(
        bytes32 protocolId,
        uint256 dstChainId,
        bytes calldata protocolAddress,
        bytes calldata functionSelector,
        bytes calldata params
    ) external;

    function proposeInOrder(
        bytes32 protocolId,
        uint256 dstChainId,
        bytes calldata protocolAddress,
        bytes calldata functionSelector,
        bytes calldata params
    ) external;
}

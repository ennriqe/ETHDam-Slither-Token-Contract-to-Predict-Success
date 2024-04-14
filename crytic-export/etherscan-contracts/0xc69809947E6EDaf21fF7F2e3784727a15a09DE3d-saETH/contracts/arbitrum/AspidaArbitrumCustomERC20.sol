// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@arbitrum/token-bridge-contracts/contracts/tokenbridge/ethereum/gateway/IL1GatewayRouter.sol";

interface IL1AspidaERC20Gateway {
    function l1Router() external view returns (address);

    function l1AspidaERC20() external view returns (address);
}

/**
 * @title Aspida's Arbitrum Custom Token
 * @author Aspida engineer
 */
abstract contract AspidaArbitrumCustomERC20 {
    /**
     * @dev Check if Arbitrum is enabled
     */
    function isArbitrumEnabled() external pure returns (uint8) {
        return uint8(0xb1);
    }

    /**
     * @dev Register Arbitrum bridge gateway
     * @param _l1gateway The address of the L1 gateway
     * @param _maxGas The maximum amount of gas
     * @param _gasPriceBid The gas price bid
     * @param _maxSubmissionCost The maximum submission cost
     */
    function registerGateway(
        address _l1gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) public payable virtual {
        require(IL1AspidaERC20Gateway(_l1gateway).l1AspidaERC20() == address(this), "L1 gateway address is invalid");

        IL1GatewayRouter(IL1AspidaERC20Gateway(_l1gateway).l1Router()).setGateway{ value: msg.value }(
            _l1gateway,
            _maxGas,
            _gasPriceBid,
            _maxSubmissionCost,
            msg.sender
        );
    }
}

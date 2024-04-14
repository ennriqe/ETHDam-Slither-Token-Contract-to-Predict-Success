// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IGaugeController {
    function getGaugeType(address gauge) external view returns (uint256);
    function checkpointGauge(address gauge) external;
    function gaugeRelativeWeight(address gauge, uint256 timestamp)
        external
        view
        returns (uint256);
}

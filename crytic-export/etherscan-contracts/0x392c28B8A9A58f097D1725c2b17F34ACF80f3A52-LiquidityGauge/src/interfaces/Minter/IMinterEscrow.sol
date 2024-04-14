// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IMinterEscrow {
    function token() external view returns (address);
    function controller() external view returns (address);

    function rate() external view returns (uint256);
    function distributionEnd() external view returns (uint256);

    function minted(address user, address gauge) external view returns (uint256);
}

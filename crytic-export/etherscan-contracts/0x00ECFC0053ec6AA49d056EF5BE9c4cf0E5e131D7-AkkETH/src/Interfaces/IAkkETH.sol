// SPDX-License-Identifier: MIT
// Akko Protocol - 2024
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IAkkETH is IERC20 {
    function mint(address _user, uint256 _share) external;

    function burn(address _user, uint256 _share) external;

    function pause() external;

    function unpause() external;
}

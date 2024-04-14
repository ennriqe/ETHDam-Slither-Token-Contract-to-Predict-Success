// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IwTAO {
  function bridgeBack(uint256 _amount, string memory _to) external returns (bool);
}

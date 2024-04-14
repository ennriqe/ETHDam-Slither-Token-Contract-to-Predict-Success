// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";

/// @author Extended implemeantion from solady/ERC20 Constract
/// @dev Added Support for Admins to Mint
contract NFTFN is ERC20 {
  /// Access Control Error
  error NotAnAdmin();

  /// Calling with Invalid Amount Error
  error InvalidAmount();

  /// Invalid Address Error
  error InvalidAddress();

  event AdminAdded(address admin);

  event AdminRemoved(address admin);

  mapping(address => uint8) public admins;

  constructor(address admin) {
    admins[admin] = 1;
  }

  modifier onlyAdmin() {
    if (admins[msg.sender] != 1) revert NotAnAdmin();
    _;
  }

  /// IERC20 Metadata Functions ///
  function name() public pure override returns (string memory) {
    return "NFTFN";
  }

  function symbol() public pure override returns (string memory) {
    return "NFTFN";
  }

  function _constantNameHash() internal pure override returns (bytes32 result) {
    return keccak256(bytes(name()));
  }

  function mint(address to, uint256 amount) public onlyAdmin {
    if (amount <= 0) {
      revert InvalidAmount();
    }

    _mint(to, amount);
  }

  /// @notice Wrapper function to Burn Tokens for anyone
  /// @param from Address to burn tokens from
  /// @param amount Amount of tokens to be burned
  function burn(address from, uint256 amount) public onlyAdmin {
    _burn(from, amount);
  }

  function addAdmin(address admin) public onlyAdmin {
    if (admin == address(0) || admins[admin] == 1) {
      revert InvalidAddress();
    }
    admins[admin] = 1;
    emit AdminAdded(admin);
  }

  function removeAdmin(address admin) public onlyAdmin {
    if (admin == msg.sender || admin == address(0)) {
      revert InvalidAddress();
    }

    admins[admin] = 0;
    emit AdminRemoved(admin);
  }
}

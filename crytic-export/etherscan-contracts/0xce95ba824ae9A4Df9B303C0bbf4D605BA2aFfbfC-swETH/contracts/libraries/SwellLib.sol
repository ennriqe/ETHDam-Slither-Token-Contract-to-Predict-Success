// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

/**
 * @title SwellLib
 * @author https://github.com/max-taylor
 * @notice This library contains roles, errors, events and functions that are widely used throughout the protocol
 */
library SwellLib {
  // ***** Roles *****
  /**
   * @dev The platform admin role
   */
  bytes32 public constant PLATFORM_ADMIN = keccak256("PLATFORM_ADMIN");

  /**
   * @dev The bot role
   */
  bytes32 public constant BOT = keccak256("BOT");

  /**
   * @dev The role used for the swETH.reprice method
   */
  bytes32 public constant REPRICER = keccak256("REPRICER");

  /**
   * @dev Used for checking all the pausing methods
   */
  bytes32 public constant PAUSER = keccak256("PAUSER");

  /**
   * @dev Used for checking all the unpausing methods
   */
  bytes32 public constant UNPAUSER = keccak256("UNPAUSER");

  /**
   * @dev Role used specifically in the deleteActiveValidators method
   */
  bytes32 public constant DELETE_ACTIVE_VALIDATORS =
    keccak256("DELETE_ACTIVE_VALIDATORS");

  /**
   * @dev Role used specifically in the processWithdrawals method
   */
  bytes32 public constant PROCESS_WITHDRAWALS =
    keccak256("PROCESS_WITHDRAWALS");

  // ***** Errors *****
  /**
   * @dev Thrown when _checkZeroAddress is called with the zero address
   */
  error CannotBeZeroAddress();

  /**
   * @dev Thrown in some contracts when the contract call is received by the fallback method
   */
  error InvalidMethodCall();

  /**
   * @dev Thrown in some contracts when ETH is sent directly to the contract
   */
  error InvalidETHDeposit();

  /**
   * @dev Thrown when interacting with a method on the protocol that is disabled via the coreMethodsPaused bool
   */
  error CoreMethodsPaused();

  /**
   * @dev Thrown when interacting with a method on the protocol that is disabled via the botMethodsPaused bool
   */
  error BotMethodsPaused();

  /**
   * @dev Thrown when interacting with a method on the protocol that is disabled via the operatorMethodsPaused bool
   */
  error OperatorMethodsPaused();

  /**
   * @dev Thrown when interacting with a method on the protocol that is disabled via the withdrawalsPaused bool
   */
  error WithdrawalsPaused();

  /**
   * @dev Thrown when calling the withdrawERC20 method and the contracts balance is 0
   */
  error NoTokensToWithdraw();

  /**
   * @dev Thrown when attempting to deposit with referrer the same all calling address
   */
  error CannotReferSelf();

  // ************************************
  // ***** Internal Methods *****
  /**
   * @dev This helper is used throughout the protocol to guard against zero addresses being passed as parameters
   * @param _address The address to check if it is the zero address
   */
  function _checkZeroAddress(address _address) internal pure {
    if (_address == address(0)) {
      revert CannotBeZeroAddress();
    }
  }
}

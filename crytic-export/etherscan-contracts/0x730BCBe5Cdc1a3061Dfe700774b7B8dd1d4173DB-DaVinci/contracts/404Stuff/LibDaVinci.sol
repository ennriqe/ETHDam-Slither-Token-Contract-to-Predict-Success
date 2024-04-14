// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

library LibDaVinci {
    // @dev The token does not exist.
    error TokenInvalid();
    // @dev The token is not ready to be traded.
    error TokenLoading();
}

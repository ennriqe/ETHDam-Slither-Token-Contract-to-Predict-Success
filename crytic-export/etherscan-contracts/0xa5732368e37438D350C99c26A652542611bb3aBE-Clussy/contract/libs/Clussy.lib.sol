// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

library LibClussy {
    /// @dev Object defintion of a airdrop phase.
    struct Phase {
        bytes32 merkleRoot;
        uint32 startTime;
        uint32 endTime;
    }
    /// @dev The token does not exist.
    error TokenInvalid();
    /// @dev The token is not ready to be traded.
    error TokenLoading();
    /// @dev An invalid minter is attempting to mint.
    error MintInvalid();
    /// @dev An invalid minter is attempting to mint.
    error MinterInvalid();
    /// @dev Transfer state has been locked already.
    error TradingLocked();
    /// @dev The max supply will be exceeded.
    error SupplyInsufficient();
    /// @dev Maximum mint amount for this wallet has been reached.
    error MintMaximum();
    /// @dev Not enough was sent to the payable function.
    error PaymentInvalid();
    /// @dev allows batch updating of metadata on Opensea
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}
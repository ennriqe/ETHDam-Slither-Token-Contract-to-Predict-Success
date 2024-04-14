// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICreion {
  // =============================================================
  //                            ERRORS
  // =============================================================
  error NotWhitelisted(address user);
  error MaxSupplyExceeded(uint256 maxSupply);
  error InsufficientPayment(uint256 required, uint256 payment);
  error PhaseSupplyExceeded(uint256 currentSupply);
  error PhaseNotActive(string activePhase);
  error PhaseWalletMaxMintExceeded(uint256 maxMintPerTx, uint256 minted);
  error TeamMintAlreadyDone();
  error NoClaimableNFT();
  error ClaimFailed();
  error ClaimNotEnabled();
  error ClaimNotDisabled();
  error ClaimRefundFailed();
  error TransferNotEnabled();
  error ListingNotEnabled();
  error PaymentFailed();
  error InsufficientContractBalance(uint256 contractBalance);
  error InsufficientWalletBalance(uint256 walletBalance);
  error MintNotEnabled();
  error MintNotDisabled();
  error PhaseDoesNotExist(uint256 phase);
  error WithdrawalFailed();

  struct NFT {
    uint256 maxSupply;
    uint256 revealPhase;
    bytes32 presaleMerkleRoot;
    bytes32 fcfsMerkleRoot;
    bytes32 publicMerkleRoot;
    bool operatorFilteringEnabled;
    bool isClaimable;
    bool isTransferable;
    bool isMintEnabled;
  }

  struct TeamMint {
    uint256 mintQty;
    address teamAddress;
    bool isMinted;
  }

  struct Phases {
    bool isActive;
    uint256 price;
    uint256 currentSupply;
    uint256 maxSupply;
    uint256 maxMintPerTx;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

struct SeasonInfo {
    uint256 seasonId;
    string description;
    bool paused;
    bool valid;
}

struct PayoutTier {
    uint256 tierId;
    string description;
    uint256 price;
    uint256 maxPerTx;
    uint256 payoutPct;
    uint256 maxSupply;
    bool paused;
    bool valid;
}

enum MintMethod {
    PURCHASE,
    AIRDROP,
    EXTERNAL_MINT
}

bytes32 constant CONTRACT_ADMIN_ROLE = keccak256("silks.contracts.roles.ContractAdminRole");
bytes32 constant MINT_ADMIN_ROLE = keccak256("silks.contracts.roles.MintAdminRole");

bytes32 constant HORSE_PURCHASING_PAUSED = keccak256('silks.contracts.paused.HorsePurchasing');

error InvalidAddress(address _address);
error InvalidSeason(uint256 _sent);
error InvalidPayoutTier(uint256 _sent);
error InvalidTokenId(uint256 _sent);
error InvalidIntValue(string _reason, uint256 _sent, uint256 _expected);
error InvalidStringValue(string _reason, string _sent, string _expected);
error InvalidExternalMintAddress(address _sender);
error MaxHorsesPerWalletExceeded(address _walletAddress);
error PayoutTierMaxSupplyExceeded(uint256 _payoutTier);
error MintFailed(string _reason, uint256 _seasonId, uint256 _payoutTier, uint256 _quantity, MintMethod _method, address _to);

library LibSilksHorseDiamond {
    bytes32 internal constant STORAGE_SLOT = keccak256('silks.contracts.storage.SilksHorseDiamond');
    
    struct Layout {
        mapping(uint256 => EnumerableSet.UintSet) seasonHorses;
        mapping(uint256 => SeasonInfo) seasonInfos;
        mapping(uint256 => PayoutTier) payoutTiers;
        mapping(uint256 => PayoutTier) horsePayoutTier;
        mapping(uint256 => EnumerableSet.UintSet) payoutTierHorses;
        mapping(uint256 => SeasonInfo) horseSeasonInfo;
        mapping(address => bool) allowedExternalMintAddresses;
        uint256 maxHorsesPerWallet;
        uint256 nextAvailableTokenId;
    }
    
    function layout()
    internal
    pure
    returns (
        Layout storage l
    ) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
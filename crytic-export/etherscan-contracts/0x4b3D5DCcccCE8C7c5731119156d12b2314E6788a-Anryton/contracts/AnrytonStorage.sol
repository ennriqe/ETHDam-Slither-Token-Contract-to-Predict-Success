// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

abstract contract AnrytonStorage {
    // State variables


    address internal _FRIEND_FAMILY;
    address internal _PRIVATE_SALE;
    address internal _PUBLIC_SALE;
    address internal _TEAM;
    address internal _RESERVES;
    address internal _STORAGE_MINTING_ALLOCATION;
    address internal _GRANTS_REWARD;
    address internal _MARKETTING;
    address internal _ADVISORS;
    address internal _LIQUIDITY_EXCHANGE_LISTING;
    address internal _STAKING;

        struct MintingSale {
        string name;
        uint160 supply;
        address walletAddress;
    }

    uint160 internal constant MAX_TOTAL_SUPPLY = 400000000 ether;
    string internal _latestSale;
    uint8 public mintingCounter;
    mapping(uint => MintingSale) public mintedSale;



    // gap
    uint256[50] internal _gap;
}

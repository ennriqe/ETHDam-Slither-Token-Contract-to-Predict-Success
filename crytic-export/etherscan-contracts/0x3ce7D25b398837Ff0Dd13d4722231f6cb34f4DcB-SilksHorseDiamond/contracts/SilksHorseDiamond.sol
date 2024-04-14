// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Importing necessary libraries and contracts
import { AccessControlInternal } from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import { AccessControlStorage } from "@solidstate/contracts/access/access_control/AccessControlStorage.sol";
import { ERC2981 } from "@solidstate/contracts/token/common/ERC2981/ERC2981.sol";
import { ERC2981Storage } from "@solidstate/contracts/token/common/ERC2981/ERC2981Storage.sol";
import { ERC721MetadataStorage } from "@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";
import { PausableInternal } from "@solidstate/contracts/security/pausable/PausableInternal.sol";
import { SolidStateDiamond } from "@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol";

// Import custom library
import "./libraries/LibSilksHorseDiamond.sol";

/**
 * @title SilksHorseDiamond
 * @dev A Solidity smart contract representing a Diamond upgradeable NFT (ERC721) with additional features.
 */
contract SilksHorseDiamond is
    AccessControlInternal,
    ERC2981,
    PausableInternal,
    SolidStateDiamond
{
    using AccessControlStorage for AccessControlStorage.Layout;
    
    /**
     * @dev Constructor for initializing the SilksHorseDiamond contract.
     * @param _contractOwner The address of the contract owner.
     * @param _tokenName The name of the NFT token.
     * @param _tokenSymbol The symbol of the NFT token.
     * @param _tokenBaseURI The base URI for metadata of NFTs.
     * @param _royaltyReceiver The address that receives royalties from NFT sales.
     * @param _royaltyBasePoints The base points (0-10000) for calculating royalties.
     * @param _seasonInfos Array of season info objects to use for initialization
     * @param _payoutTiers Array of pay out tier objects to use for initialization
     */
    constructor(
        address _contractOwner,
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenBaseURI,
        uint256 _startTokenId,
        address _royaltyReceiver,
        uint16 _royaltyBasePoints,
        uint256 _maxHorsesPerWallet,
        SeasonInfo[] memory _seasonInfos,
        PayoutTier[] memory _payoutTiers
    )
    SolidStateDiamond()
    {
        // Setting metadata for the NFT
        ERC721MetadataStorage.layout().name = _tokenName;
        ERC721MetadataStorage.layout().symbol = _tokenSymbol;
        ERC721MetadataStorage.layout().baseURI = _tokenBaseURI;
        
        // Setting default royalty information
        ERC2981Storage.layout().defaultRoyaltyReceiver = _royaltyReceiver;
        ERC2981Storage.layout().defaultRoyaltyBPS = _royaltyBasePoints;
        
        // Setting the contract owner and pausing the contract initially
        _setOwner(_contractOwner);
        _pause();
        
        // Granting roles to the contract owner
        _grantRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, _contractOwner);
        
        // Defining and granting admin roles for the contract
        _setRoleAdmin(CONTRACT_ADMIN_ROLE, AccessControlStorage.DEFAULT_ADMIN_ROLE);
        _grantRole(CONTRACT_ADMIN_ROLE, _contractOwner);
        
        // Defining and granting admin roles for minting NFTs
        _setRoleAdmin(MINT_ADMIN_ROLE, AccessControlStorage.DEFAULT_ADMIN_ROLE);
        _grantRole(MINT_ADMIN_ROLE, _contractOwner);
    
        LibSilksHorseDiamond.Layout storage lsh = LibSilksHorseDiamond.layout();
        lsh.nextAvailableTokenId = _startTokenId;
        lsh.maxHorsesPerWallet = _maxHorsesPerWallet;
        for (uint256 i = 0; i < _seasonInfos.length; i++){
            lsh.seasonInfos[_seasonInfos[i].seasonId] = _seasonInfos[i];
        }
        
        for (uint256 i = 0; i < _payoutTiers.length; i++){
            lsh.payoutTiers[_payoutTiers[i].tierId] = _payoutTiers[i];
        }
    }
}

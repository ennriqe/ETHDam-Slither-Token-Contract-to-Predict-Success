// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import necessary libraries and contracts
import { AccessControlInternal } from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import { ERC165BaseInternal } from "@solidstate/contracts/introspection/ERC165/base/ERC165BaseInternal.sol";
import { ERC721Base } from "@solidstate/contracts/token/ERC721/base/ERC721Base.sol";
import { ERC721BaseInternal } from "@solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol";
import { ERC721Enumerable } from "@solidstate/contracts/token/ERC721/enumerable/ERC721Enumerable.sol";
import { ERC721Metadata } from "@solidstate/contracts/token/ERC721/metadata/ERC721Metadata.sol";
import { PartiallyPausableInternal } from "@solidstate/contracts/security/partially_pausable/PartiallyPausableInternal.sol";
import { PausableInternal } from "@solidstate/contracts/security/pausable/PausableInternal.sol";
import "../libraries/LibSilksHorseDiamond.sol";

/**
 * @title ERC721Facet
 * @dev A Solidity smart contract representing the ERC721 facet of the SilksHorseDiamond contract.
 * This facet provides functionality for purchasing and airdropping NFTs (horses) and handles pausing functionality.
 */
contract ERC721Facet is
    AccessControlInternal,
    ERC165BaseInternal,
    ERC721Base,
    ERC721Enumerable,
    ERC721Metadata,
    PartiallyPausableInternal,
    PausableInternal
{
    using EnumerableSet for EnumerableSet.UintSet;
    
    event HorseMinted(
        MintMethod indexed method,
        uint256 indexed seasonId,
        uint256 indexed payoutTier,
        address to,
        uint256 tokenId
    );
    
    /**
     * @dev Purchase horses by providing season, payout tier, and quantity.
     * @param _seasonId The ID of the season from which to purchase horses.
     * @param _payoutTier The ID of the payout tier for the purchase.
     * @param _quantity The quantity of horses to purchase.
     */
    function purchase(
        uint256 _seasonId,
        uint256 _payoutTier,
        uint256 _quantity
    )
    public
    payable
    whenNotPaused
    whenNotPartiallyPaused(HORSE_PURCHASING_PAUSED)
    {
        // Check if the sent Ether amount is valid
        PayoutTier storage payoutTier = LibSilksHorseDiamond.layout().payoutTiers[_payoutTier];
        uint256 expectedEthTotal = payoutTier.price * _quantity;
        if (expectedEthTotal != msg.value){
            revert InvalidIntValue(
                "INV_ETH_TOTAL",
                msg.value,
                expectedEthTotal
            );
        }
        
        // Check if the purchase quantity is within the allowed limit per transaction
        if (payoutTier.maxPerTx != 0 && _quantity > payoutTier.maxPerTx){
            revert InvalidIntValue(
                "PER_TX_ERROR",
                _quantity,
                payoutTier.maxPerTx
            );
        }
        
        // Mint the specified quantity of horses to the sender
        _mintHorses(_seasonId, _payoutTier, _quantity, MintMethod.PURCHASE, msg.sender);
    }
    
    /**
     * @dev Airdrop horses by providing season, payout tier, quantity, and the recipient address.
     * @param _seasonId The ID of the season for the airdrop.
     * @param _payoutTier The ID of the payout tier for the airdrop.
     * @param _quantity The quantity of horses to airdrop.
     * @param _to The address to receive the airdropped horses.
     */
    function airdrop(
        uint256 _seasonId,
        uint256 _payoutTier,
        uint256 _quantity,
        address _to
    )
    public
    onlyRole(MINT_ADMIN_ROLE)
    {
        // Mint the specified quantity of horses and send them to the specified recipient
        _mintHorses(_seasonId, _payoutTier, _quantity, MintMethod.AIRDROP, _to);
    }
    
    /**
    * @dev Allows an external address to mint horses by providing season, payout tier, quantity, and the recipient address.
    * Checks if the calling address is in the allowed list of external mint addresses before minting.
    * @param _seasonId The ID of the season for the minted horses.
    * @param _payoutTier The ID of the payout tier for the minted horses.
    * @param _quantity The quantity of horses to mint.
    * @param _to The address to receive the minted horses.
    */
    function externalMint(
        uint256 _seasonId,
        uint256 _payoutTier,
        uint256 _quantity,
        address _to
    ) external
    {
        // Check if the calling address is in the list of allowed external mint addresses
        bool inAllowedList = LibSilksHorseDiamond.layout().allowedExternalMintAddresses[msg.sender];
        if (!inAllowedList){
            revert InvalidExternalMintAddress(
                msg.sender
            );
        }
        
        // Call the internal function to mint the horses
        _mintHorses(_seasonId, _payoutTier, _quantity, MintMethod.EXTERNAL_MINT, _to);
    }
    
    /**
     * @dev Mint horses based on season, payout tier, quantity, minting method, and recipient address.
     * @param _seasonId The ID of the season for minting horses.
     * @param _payoutTier The ID of the payout tier for minting horses.
     * @param _quantity The quantity of horses to mint.
     * @param _method The minting method used for the horses.
     * @param _to The address to receive the minted horses.
     * @dev This function is used to mint a specified quantity of horse tokens and associate them with a season and payout tier.
     * The minted horse tokens are then assigned to the provided recipient address. The function performs various checks
     * to ensure the specified season and payout tier are valid and not paused. It also checks for successful association of
     * horse tokens with the season and logs minting events.
     * @dev Emits a HorseMinted event upon successful minting.
     * @dev Reverts with specific error messages in case of invalid or paused season, invalid or paused payout tier,
     * failed association of tokens with the season, or any other minting failure.
     */
    function _mintHorses(
        uint256 _seasonId,
        uint256 _payoutTier,
        uint256 _quantity,
        MintMethod _method,
        address _to
    )
    private
    {
        // Check if the _quantity being minted will cause the maximum number of assets in wallet to be exceeded
        uint256 maxHorsesPerWallet = LibSilksHorseDiamond.layout().maxHorsesPerWallet;
        if (maxHorsesPerWallet > 0 &&( _balanceOf(_to) + _quantity) > maxHorsesPerWallet){
            revert MaxHorsesPerWalletExceeded(
                _to
            );
        }
        
        // Check if the specified season and payout tier are valid and not paused
        SeasonInfo storage seasonInfo = LibSilksHorseDiamond.layout().seasonInfos[_seasonId];
        if (seasonInfo.paused || !seasonInfo.valid){
            revert InvalidSeason(
                _seasonId
            );
        }
        
        PayoutTier storage payoutTier = LibSilksHorseDiamond.layout().payoutTiers[_payoutTier];
        if (payoutTier.paused || !payoutTier.valid){
            revert InvalidPayoutTier(
                _payoutTier
            );
        }
        
        LibSilksHorseDiamond.Layout storage lsh = LibSilksHorseDiamond.layout();
        
        EnumerableSet.UintSet storage payoutTierHorses = lsh.payoutTierHorses[_payoutTier];
        if (payoutTier.maxSupply > 0 && (payoutTierHorses.length() + _quantity) > payoutTier.maxSupply){
            revert PayoutTierMaxSupplyExceeded(
                _payoutTier
            );
        }
    
        EnumerableSet.UintSet storage seasonHorses = lsh.seasonHorses[_seasonId];
        uint256 nextAvailableTokenId = lsh.nextAvailableTokenId;
        uint256 i = 0;
        // Mint the specified quantity of horses, associate them with the season, and set payout percentages
        for (; i < _quantity;) {
            uint256 _newTokenId = nextAvailableTokenId + i;
            if (!seasonHorses.add(_newTokenId)){
                revert MintFailed(
                    "TOKEN_CROP_ASSOCIATION_ERROR",
                    _seasonId,
                    _payoutTier,
                    _quantity,
                    _method,
                    _to
                );
            }
            if (!payoutTierHorses.add(_newTokenId)){
                revert MintFailed(
                    "TOKEN_PAYOUT_TIER_ASSOCIATION_ERROR",
                    _seasonId,
                    _payoutTier,
                    _quantity,
                    _method,
                    _to
                );
            }
            lsh.horsePayoutTier[_newTokenId] = payoutTier;
            lsh.horseSeasonInfo[_newTokenId] = seasonInfo;
            _safeMint(_to, _newTokenId);
            emit HorseMinted(_method, _seasonId, _payoutTier, _to, _newTokenId);
            unchecked {
                i++;
            }
        }
        lsh.nextAvailableTokenId = nextAvailableTokenId + i;
    }
    
    /**
     * @dev Hook function called before token transfer, inherited from ERC721Metadata.
     * @param from The sender of the tokens.
     * @param to The recipient of the tokens.
     * @param tokenId The ID of the token being transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
    internal
    virtual
    override(
        ERC721Metadata,
        ERC721BaseInternal
    )
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(
        bytes4 interfaceId
    )
    external
    view
    returns (
        bool
    )
    {
        return super._supportsInterface(interfaceId);
    }
}

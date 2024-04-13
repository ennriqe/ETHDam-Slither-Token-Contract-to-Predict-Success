// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721C, ERC721OpenZeppelin} from "@limitbreak/creator-token-standards/src/erc721c/ERC721C.sol";
import {
    BasicRoyalties, ERC2981
} from "@limitbreak/creator-token-standards/src/programmable-royalties/BasicRoyalties.sol";
import {OwnableBasic, Ownable} from "@limitbreak/creator-token-standards/src/access/OwnableBasic.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

error NotOwnerOfToken();
error TokenDoesNotExist();
error ArtifactNotSet();
error RevealNotOpen();

// Interface for Okay Dogs Artifacts contract
interface IArtifact {
    function burnToReveal(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

/**
 * @title OkayDogs
 * @author cygaar <@0xCygaar>
 */
contract OkayDogs is ERC721C, BasicRoyalties, OwnableBasic {
    using Strings for uint256;

    // Address of the artifact NFT that will call mint to this contract
    address public artifactAddress;

    // Denotes whether or not the reveal process is open
    bool public revealOpen;

    // Denotes whether or not bulk revealing is open
    bool public bulkRevealOpen;

    // Base metadata uri
    string private _baseTokenURI;

    constructor(address artifact, address royaltyReceiver_, string memory name_, string memory symbol_)
        ERC721OpenZeppelin(name_, symbol_)
        BasicRoyalties(royaltyReceiver_, 500)
    {
        artifactAddress = artifact;
    }

    /**
     * Acts as a burn to reveal function. Users will burn an Artifact NFT
     * and receive an Okay Dog afterwards. Token ids will match 1:1.
     * @dev The msg.sender must be the owner of the Artifact being burned.
     * @param receiver Destination address
     * @param tokenId ID of the artifact to burn
     */
    function reveal(address receiver, uint256 tokenId) external {
        if (artifactAddress == address(0)) revert ArtifactNotSet();

        if (!revealOpen) revert RevealNotOpen();

        // Verify ownership of tokenId
        if (IArtifact(artifactAddress).ownerOf(tokenId) != msg.sender) {
            revert NotOwnerOfToken();
        }

        // Burn artifact token first
        IArtifact(artifactAddress).burnToReveal(tokenId);

        // Mint the OkayDog
        _mint(receiver, tokenId);
    }

    /**
     * Same as reveal, but allows for bulk revealing.
     * @dev The msg.sender must be the owner of each Artifact being burned.
     * @param receiver Destination address
     * @param tokenIds List of Ids to burn
     */
    function bulkReveal(address receiver, uint256[] calldata tokenIds) external {
        if (artifactAddress == address(0)) revert ArtifactNotSet();

        if (!bulkRevealOpen && _msgSender() != owner()) revert RevealNotOpen();

        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            if (IArtifact(artifactAddress).ownerOf(tokenId) != msg.sender) {
                revert NotOwnerOfToken();
            }
            IArtifact(artifactAddress).burnToReveal(tokenId);
        }

        for (uint256 i; i < tokenIds.length; ++i) {
            _mint(receiver, tokenIds[i]);
        }
    }

    /**
     * Opens up the reveal process. Only callable by the owner.
     * @param value Boolean denoting the new status
     */
    function setRevealOpen(bool value) external onlyOwner {
        revealOpen = value;
    }

    /**
     * Opens up the bulk reveal process. Only callable by the owner.
     * @param value Boolean denoting the new status
     */
    function setBulkRevealOpen(bool value) external onlyOwner {
        bulkRevealOpen = value;
    }

    /**
     * Sets the address of the artifact contract. Only callable by the owner.
     * @param artifact Address of the artifact contract.
     */
    function setArtifactContract(address artifact) external onlyOwner {
        artifactAddress = artifact;
    }

    /**
     * Sets the default royalty rate for all sales.
     * @param receiver The royalty receiver
     * @param feeNumerator The royalty rate
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public {
        _requireCallerIsContractOwner();
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * Sets the per token royalty rate.
     * @param tokenId ID of the NFT
     * @param receiver The royalty receiver
     * @param feeNumerator The royalty rate
     */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public {
        _requireCallerIsContractOwner();
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * Overridden supportsInterface with IERC721 support and ERC2981 support
     * @param interfaceId Interface Id to check
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721C, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Owner-only function to set the base uri used for metadata.
     * @param baseURI uri to use for metadata
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Function to retrieve the metadata uri for a given token. Reverts for tokens that don't exist.
     * @param tokenId Token Id to get metadata for
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

contract PeplicatorNFT is ERC721, ERC721Burnable, ERC721Enumerable, AccessControl, Ownable {
  error ExceedsMintLimit();
  error InvalidMaxSupply();
  error InvalidMintLimit();
  error MetadataIsFrozen();
  error NotEnoughSupply();

  event BatchMetadataUpdate(uint256 __fromTokenId, uint256 __toTokenId);
  event MaxSupplyUpdate(uint256 __maxSupply);
  event MetadataUpdate(uint256 __tokenId);
  event MintLimitUpdate(uint256 __mintLimit);

  // Used to determine if metadata is frozen
  bool private _metadataIsFrozen = false;

  // Used to track max supply
  uint256 private _maxSupply = 1000000;

  // Used to track mint limit
  uint256 private _mintLimit = 100;

  // Used to track id of next token
  uint256 private _nextTokenID = 1;

  // Use to determine base URI for all tokens
  string private _tokenBaseURI = '';

  // Minter Role used in minting operations
  bytes32 constant _MINTER_ROLE = bytes32('MINTER_ROLE');

  /**
   * @dev Sets name/symbol and grants initial roles to owner upon construction.
   */
  constructor(string memory __name, string memory __symbol) ERC721(__name, __symbol) {
    address sender = _msgSender();

    _grantRole(DEFAULT_ADMIN_ROLE, sender);
    _grantRole(_MINTER_ROLE, sender);
  }

  ////////////////////////////////////////////////////////////////////////////
  // INTERNALS
  ////////////////////////////////////////////////////////////////////////////

  function _beforeTokenTransfer(
    address __from,
    address __to,
    uint256 __tokenID,
    uint256 __batchSize
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(__from, __to, __tokenID, __batchSize);
  }

  ////////////////////////////////////////////////////////////////////////////
  // ADMIN
  ////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Used to freeze metadata.
   *
   */
  function freezeMetadata() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _metadataIsFrozen = true;
  }

  /**
   * @dev Used to refresh metadata.
   *
   * Emits {MetadataUpdate} event(s).
   *
   */
  function refreshMetadata(uint256 __tokenID) external onlyRole(DEFAULT_ADMIN_ROLE) {
    emit MetadataUpdate(__tokenID);
  }

  /**
   * @dev Used to refresh all metadata.
   *
   * Emits {BatchMetadataUpdate} event(s).
   *
   */
  function refreshMetadataAll() external onlyRole(DEFAULT_ADMIN_ROLE) {
    emit BatchMetadataUpdate(1, totalSupply());
  }

  /**
   * @dev Used to set the base URI.
   *
   * Emits {BatchMetadataUpdate} event(s).
   *
   */
  function setBaseURI(string memory __baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_metadataIsFrozen) {
      revert MetadataIsFrozen();
    }

    _tokenBaseURI = __baseURI;

    emit BatchMetadataUpdate(1, totalSupply());
  }

  /**
   * @dev Used to set the max supply.
   *
   * Emits {MaxSupplyUpdate} event(s).
   *
   */
  function setMaxSupply(uint256 __maxSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (__maxSupply < _nextTokenID - 1) {
      revert InvalidMaxSupply();
    }

    _maxSupply = __maxSupply;

    emit MaxSupplyUpdate(__maxSupply);
  }

  /**
   * @dev Used to set the mint limit.
   *
   * Emits {MintLimitUpdate} event(s).
   *
   */
  function setMintLimit(uint256 __mintLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (__mintLimit == 0) {
      revert InvalidMintLimit();
    }

    _mintLimit = __mintLimit;

    emit MintLimitUpdate(__mintLimit);
  }

  ////////////////////////////////////////////////////////////////////////////
  // MINTER
  ////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Used to mint token(s).
   */
  function mint(address __account, uint256 __amount) external onlyRole(_MINTER_ROLE) {
    if (totalSupply() + __amount > _maxSupply) {
      revert NotEnoughSupply();
    }
    if (__amount > _mintLimit) {
      revert ExceedsMintLimit();
    }

    for (uint256 i = 0; i < __amount; i++) {
      uint256 tokenID = _nextTokenID++;
      _safeMint(__account, tokenID);
    }
  }

  ////////////////////////////////////////////////////////////////////////////
  // READS
  ////////////////////////////////////////////////////////////////////////////

  function _baseURI() internal view virtual override returns (string memory) {
    return _tokenBaseURI;
  }

  /**
   * @dev Retrieve the max supply.
   */
  function maxSupply() external view returns (uint256) {
    return _maxSupply;
  }

  /**
   * @dev Check if metadata is frozen.
   */
  function metadataIsFrozen() external view returns (bool) {
    return _metadataIsFrozen;
  }

  /**
   * @dev Retrieve the mint limit.
   */
  function mintLimit() external view returns (uint256) {
    return _mintLimit;
  }

  /**
   * @dev Retrieve the id of the next token.
   */
  function nextTokenID() external view returns (uint256) {
    return _nextTokenID;
  }

  /**
   * @dev See {ERC721-supportsInterface} and {AccessControl-supportsInterface}.
   */
  function supportsInterface(
    bytes4 __interfaceId
  ) public view virtual override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
    return super.supportsInterface(__interfaceId);
  }
}

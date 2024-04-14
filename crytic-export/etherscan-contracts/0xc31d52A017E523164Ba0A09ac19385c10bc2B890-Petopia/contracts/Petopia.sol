// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "lib/dynamic-contracts/src/presets/BaseRouter.sol";
import "./SignatureAction.sol";
import "./DelayedReveal.sol";
import "./LazyMint.sol";

contract Petopia is
ERC721ABurnable,
AccessControl,
ERC2771Context,
ERC2981,
Multicall,
BaseRouter,
SignatureAction,
DelayedReveal,
LazyMint
{
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    mapping(uint256 => bytes32) private tokenIdOffset;
    /// @notice Emitted when tokens are claimed via `claimWithSignature`.
    event TokensClaimed(
        address indexed claimer,
        address indexed receiver,
        uint256 startTokenId,
        uint256 quantityClaimed
    );

    /*///////////////////////////////////////////////////////////////
                    Constructor and Initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address _royaltyRecipient,
        uint16 _royaltyBps,
        Extension[] memory _extensions,
        address _trustedForwarders
    )
    BaseRouter(_extensions)
    ERC2771Context(_trustedForwarders)
    ERC721A(_name, _symbol)
    {
        _baseContractURI = _contractURI;
        _setupRoles(_defaultAdmin);
        _setDefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    function _setupRoles(address _defaultAdmin) internal {
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(TRANSFER_ROLE, DEFAULT_ADMIN_ROLE);

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(MINTER_ROLE, _defaultAdmin);
        _grantRole(TRANSFER_ROLE, address(0));
    }

    function mint(address to, uint quantity) external onlyRole(MINTER_ROLE) {
        uint256 tokenIdToMint = _nextTokenId();
        if (tokenIdToMint + quantity > nextTokenIdToLazyMint) {
            revert("!Tokens");
        }
        _mint(to, quantity);
    }

    /*///////////////////////////////////////////////////////////////
              Internal functions
    //////////////////////////////////////////////////////////////*/

    function _beforeTokenTransfers(
        address from,
        address to,
        uint startTokenId,
        uint quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!hasRole(TRANSFER_ROLE, from) && !hasRole(TRANSFER_ROLE, to)) {
                revert("!TRANSFER");
            }
        }
    }

    function _canSetExtension() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _isAuthorizedSigner(address _signer) internal view override returns (bool) {
        return hasRole(MINTER_ROLE, _signer);
    }

    /*///////////////////////////////////////////////////////////////
                   Lazy minting + delayed-reveal logic
   //////////////////////////////////////////////////////////////*

   /**
    *  @dev Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
     *       The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
     */
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _data
    ) external onlyRole(MINTER_ROLE) returns (uint256 batchId) {
        if (_data.length > 0) {
            (bytes memory encryptedURI, bytes32 provenanceHash) = abi.decode(_data, (bytes, bytes32));
            if (encryptedURI.length != 0 && provenanceHash != "") {
                _setEncryptedData(nextTokenIdToLazyMint + _amount, _data);
            }
        }

        return _lazyMint(_amount, _baseURIForTokens, _data);
    }

    function claimWithSignature(GenericRequest calldata _req, bytes calldata _signature)
    external
    returns (address signer)
    {
        (
            address to,
            uint256 quantity
        ) = abi.decode(_req.data, (address, uint256));

        if (quantity == 0) {
            revert("qty");
        }

        uint256 tokenIdToMint = _nextTokenId();
        if (tokenIdToMint + quantity > nextTokenIdToLazyMint) {
            revert("!Tokens");
        }
        // Verify and process payload.
        signer = _processRequest(_req, _signature);

        // Mint tokens.
        _mint(to, quantity);

        emit TokensClaimed(_msgSender(), to, tokenIdToMint, quantity);
    }

    /// @dev Lets an account with `MINTER_ROLE` reveal the URI for a batch of 'delayed-reveal' NFTs.
    function reveal(uint256 _index, bytes calldata _key)
    external
    onlyRole(MINTER_ROLE)
    returns (string memory revealedURI)
    {
        uint256 batchId = getBatchIdAtIndex(_index);
        revealedURI = getRevealURI(batchId, _key);

        _setEncryptedData(batchId, "");
        _setBaseURI(batchId, revealedURI);

        _scrambleOffset(batchId, _key);

        emit TokenURIRevealed(_index, revealedURI);
    }
    /*///////////////////////////////////////////////////////////////
                  Metadata, EIP 165 / 721 / 2981 / 2771 logic
    //////////////////////////////////////////////////////////////*/
    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        (uint256 batchId,uint256 index) = _getBatchId(_tokenId);
        string memory batchUri = _getBaseURI(_tokenId);

        if (isEncryptedBatch(batchId)) {
            return string(abi.encodePacked(batchUri, "0"));
        } else {
            uint256 fairMetadataId = _getFairMetadataId(_tokenId, batchId, index);
            return string(abi.encodePacked(batchUri, _toString(fairMetadataId)));
        }
    }

    /// @dev Returns the fair metadata ID for a given tokenId.
    function _getFairMetadataId(
        uint256 _tokenId,
        uint256 _batchId,
        uint256 _indexOfBatchId
    ) private view returns (uint256 fairMetadataId) {
        bytes32 bytesRandom = tokenIdOffset[_batchId];
        if (bytesRandom == bytes32(0)) {
            return _tokenId;
        }

        uint256 randomness = uint256(bytesRandom);
        uint256 prevBatchId;
        if (_indexOfBatchId > 0) {
            prevBatchId = getBatchIdAtIndex(_indexOfBatchId - 1);
        }

        uint256 batchSize = _batchId - prevBatchId;
        uint256 offset = randomness % batchSize;
        fairMetadataId = prevBatchId + (_tokenId + offset) % batchSize;
    }

    string private _baseContractURI;

    function contractURI() public view returns (string memory) {
        return _baseContractURI;
    }

    function setContractURI(string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseContractURI = _uri;
    }

    function setBaseURI(uint256 _batchId, string memory _baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(_batchId, _baseURI);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControl, ERC721A, IERC721A, ERC2981)
    returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /// @dev Scrambles tokenId offset for a given batchId.
    function _scrambleOffset(uint256 _batchId, bytes calldata _seed) private {
        tokenIdOffset[_batchId] = keccak256(abi.encodePacked(_seed, block.prevrandao, _msgSender(), block.timestamp, blockhash(block.number - 1)));
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function _msgSender()
    internal
    view
    virtual
    override(Context, ERC2771Context)
    returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
    internal
    view
    virtual
    override(Context, ERC2771Context)
    returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view virtual override(ERC2771Context, Context) returns (uint) {
        return ERC2771Context._contextSuffixLength();
    }
}

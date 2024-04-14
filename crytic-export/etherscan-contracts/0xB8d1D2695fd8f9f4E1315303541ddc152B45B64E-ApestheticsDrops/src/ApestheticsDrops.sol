// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import {ERC1155} from "@thirdweb-dev/contracts/eip/ERC1155.sol";

import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "@thirdweb-dev/contracts/extension/Royalty.sol";
import "@thirdweb-dev/contracts/extension/BatchMintMetadata.sol";
import "@thirdweb-dev/contracts/extension/PrimarySale.sol";
import "@thirdweb-dev/contracts/extension/Drop1155.sol";
import "@thirdweb-dev/contracts/extension/LazyMint.sol";
import "@thirdweb-dev/contracts/extension/DelayedReveal.sol";

import {CurrencyTransferLib} from "@thirdweb-dev/contracts/lib/CurrencyTransferLib.sol";
import "@thirdweb-dev/contracts/lib/Strings.sol";


//░█████╗░██████╗░███████╗░██████╗████████╗██╗░░██╗███████╗████████╗██╗░█████╗░░██████╗
//██╔══██╗██╔══██╗██╔════╝██╔════╝╚══██╔══╝██║░░██║██╔════╝╚══██╔══╝██║██╔══██╗██╔════╝
//███████║██████╔╝█████╗░░╚█████╗░░░░██║░░░███████║█████╗░░░░░██║░░░██║██║░░╚═╝╚█████╗░
//██╔══██║██╔═══╝░██╔══╝░░░╚═══██╗░░░██║░░░██╔══██║██╔══╝░░░░░██║░░░██║██║░░██╗░╚═══██╗
//██║░░██║██║░░░░░███████╗██████╔╝░░░██║░░░██║░░██║███████╗░░░██║░░░██║╚█████╔╝██████╔╝
//╚═╝░░╚═╝╚═╝░░░░░╚══════╝╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░╚════╝░╚═════╝░


contract ApestheticsDrops is
    ERC1155,
    ContractMetadata,
    Ownable,
    Royalty,
    Multicall,
    BatchMintMetadata,
    PrimarySale,
    LazyMint,
    DelayedReveal,
    Drop1155
{
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////
                        Mappings
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns the total supply of NFTs of a given tokenId
     *  @dev Mapping from tokenId => total circulating supply of NFTs of that tokenId.
     */
    mapping(uint256 => uint256) public totalSupply;

    /// @dev Mapping from token ID => maximum possible total circulating supply of tokens with that ID.
    mapping(uint256 => uint256) public maxTotalSupply;

    /// @dev Mapping from token ID => the address of the recipient of primary sales.
    mapping(uint256 => address) public saleRecipient;

    /*///////////////////////////////////////////////////////////////
                               Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when the global max supply of a token is updated.
    event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply);

    /// @dev Emitted when the sale recipient for a particular tokenId is updated.
    event SaleRecipientForTokenUpdated(uint256 indexed tokenId, address saleRecipient);

    event TokenPurchased(address indexed buyer, uint256 indexed tokenId, uint256 quantity);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with the given parameters.
     *
     * @param _defaultAdmin         The default admin for the contract.
     * @param _name                 The name of the contract.
     * @param _symbol               The symbol of the contract.
     * @param _royaltyRecipient     The address to which royalties should be sent.
     * @param _royaltyBps           The royalty basis points to be charged. Max = 10000 (10000 = 100%, 1000 = 10%)
     * @param _primarySaleRecipient The address to which primary sale revenue should be sent.
     */
    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    ) ERC1155(_name, _symbol) {
        _setupOwner(_defaultAdmin);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_primarySaleRecipient);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC165 Logic
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See ERC165: https://eips.ethereum.org/EIPS/eip-165
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c || // ERC165 Interface ID for ERC1155MetadataURI
            interfaceId == type(IERC2981).interfaceId; // ERC165 ID for ERC2981
    }

    /*//////////////////////////////////////////////////////////////
                        Minting/burning logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Lets an owner or approved operator burn NFTs of the given tokenId.
     *
     *  @param _owner   The owner of the NFT to burn.
     *  @param _tokenId The tokenId of the NFT to burn.
     *  @param _amount  The amount of the NFT to burn.
     */
    function burn(address _owner, uint256 _tokenId, uint256 _amount) external virtual {
        address caller = msg.sender;

        require(caller == _owner || isApprovedForAll[_owner][caller], "Unapproved caller");
        require(balanceOf[_owner][_tokenId] >= _amount, "Not enough tokens owned");

        _burn(_owner, _tokenId, _amount);
    }

    /**
     *  @notice         Lets an owner or approved operator burn NFTs of the given tokenIds.
     *
     *  @param _owner    The owner of the NFTs to burn.
     *  @param _tokenIds The tokenIds of the NFTs to burn.
     *  @param _amounts  The amounts of the NFTs to burn.
     */
    function burnBatch(address _owner, uint256[] memory _tokenIds, uint256[] memory _amounts) external virtual {
        address caller = msg.sender;

        require(caller == _owner || isApprovedForAll[_owner][caller], "Unapproved caller");
        require(_tokenIds.length == _amounts.length, "Length mismatch");

        for (uint256 i = 0; i < _tokenIds.length; i += 1) {
            require(balanceOf[_owner][_tokenIds[i]] >= _amounts[i], "Not enough tokens owned");
        }

        _burnBatch(_owner, _tokenIds, _amounts);
    }

    /*///////////////////////////////////////////////////////////////
                    Overriden metadata logic
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice         Returns the metadata URI for an NFT.
     * @dev            See `BatchMintMetadata` for handling of metadata in this contract.
     *
     * @param _tokenId The tokenId of an NFT.
     * @return         The metadata URI for the given NFT.
     */
    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        (uint256 batchId,) = _getBatchId(_tokenId);
        string memory batchUri = _getBaseURI(_tokenId);

        if (isEncryptedBatch(batchId)) {
            return string(abi.encodePacked(batchUri, "0"));
        } else {
            return string(abi.encodePacked(batchUri, _tokenId.toString()));
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Delayed reveal logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice       Lets an authorized address reveal a batch of delayed reveal NFTs.
     *
     *  @param _index       The ID for the batch of delayed-reveal NFTs to reveal.
     *  @param _key         The key with which the base URI for the relevant batch of NFTs was encrypted.
     *  @return revealedURI The revealed URI for the batch of NFTs.
     */
    function reveal(uint256 _index, bytes calldata _key) public virtual override returns (string memory revealedURI) {
        require(_canReveal(), "Not authorized");

        uint256 batchId = getBatchIdAtIndex(_index);
        revealedURI = getRevealURI(batchId, _key);

        _setEncryptedData(batchId, "");
        _setBaseURI(batchId, revealedURI);

        emit TokenURIRevealed(_index, revealedURI);
    }

    /*///////////////////////////////////////////////////////////////
                    Overriden lazy minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice                  Lets an authorized address lazy mint a given amount of NFTs.
     *
     *  @param _amount           The number of NFTs to lazy mint.
     *  @param _baseURIForTokens The placeholder base URI for the 'n' number of NFTs being lazy minted, where the
     *                           metadata for each of those NFTs is `${baseURIForTokens}/${tokenId}`.
     *  @param _data             The encrypted base URI + provenance hash for the batch of NFTs being lazy minted.
     *  @return batchId          A unique integer identifier for the batch of NFTs lazy minted together.
     */
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _data
    ) public override returns (uint256 batchId) {
        if (_data.length > 0) {
            (bytes memory encryptedURI, bytes32 provenanceHash) = abi.decode(_data, (bytes, bytes32));
            if (encryptedURI.length != 0 && provenanceHash != "") {
                _setEncryptedData(nextTokenIdToLazyMint + _amount, _data);
            }
        }

        return LazyMint.lazyMint(_amount, _baseURIForTokens, _data);
    }

    /// @notice The tokenId assigned to the next new NFT to be lazy minted.
    function nextTokenIdToMint() public view virtual returns (uint256) {
        return nextTokenIdToLazyMint;
    }

    /*///////////////////////////////////////////////////////////////
                        Setter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a module admin set a max total supply for token.
    function setMaxTotalSupply(uint256 _tokenId, uint256 _maxTotalSupply) external {
        require(_canSetClaimConditions(), "Not authorized");

        maxTotalSupply[_tokenId] = _maxTotalSupply;
        emit MaxTotalSupplyUpdated(_tokenId, _maxTotalSupply);
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setSaleRecipientForToken(uint256 _tokenId, address _saleRecipient) external {
        require(_canSetPrimarySaleRecipient(), "Not authorized");
        saleRecipient[_tokenId] = _saleRecipient;
        emit SaleRecipientForTokenUpdated(_tokenId, _saleRecipient);
    }

    /**
     * @notice Updates the base URI for a batch of tokens.
     *
     * @param _index Index of the desired batch in batchIds array.
     * @param _uri   the new base URI for the batch.
     */
    function updateBatchBaseURI(uint256 _index, string calldata _uri) external {
        require(_canSetContractURI(), "Not authorized");
        uint256 batchId = getBatchIdAtIndex(_index);
        _setBaseURI(batchId, _uri);
    }

    /**
     * @notice Freezes the base URI for a batch of tokens.
     *
     * @param _index Index of the desired batch in batchIds array.
     */
    function freezeBatchBaseURI(uint256 _index) external {
        require(_canSetContractURI(), "Not authorized");
        uint256 batchId = getBatchIdAtIndex(_index);
        _freezeBaseURI(batchId);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Runs before every `claim` function call.
     *
     * @param _tokenId The tokenId of the NFT being claimed.
     */
    function _beforeClaim(
        uint256 _tokenId,
        address,
        uint256 _quantity,
        address,
        uint256,
        AllowlistProof calldata,
        bytes memory
    ) internal view virtual override {
        if (_tokenId >= nextTokenIdToLazyMint) {
            revert("Not enough minted tokens");
        }
        require(
            maxTotalSupply[_tokenId] == 0 || totalSupply[_tokenId] + _quantity <= maxTotalSupply[_tokenId],
            "exceed max total supply"
        );
    }

    /**
     * @dev Collects and distributes the primary sale value of NFTs being claimed.
     *
     * @param _primarySaleRecipient The address to which primary sale revenue should be sent.
     * @param _quantityToClaim      The quantity of NFTs being claimed.
     * @param _currency             The currency in which the NFTs are being sold.
     * @param _pricePerToken        The price per NFT being claimed.
     */

    function collectPriceOnClaim(
        uint256 _tokenId,
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual override {
        if (_pricePerToken == 0) {
            require(msg.value == 0, "!Value");
            return;
        }

        uint256 totalPrice = _quantityToClaim * _pricePerToken;

        bool validMsgValue;
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            validMsgValue = msg.value == totalPrice;
        } else {
            validMsgValue = msg.value == 0;
        }
        require(validMsgValue, "Invalid msg value");

        address _saleRecipient = _primarySaleRecipient == address(0)
            ? (saleRecipient[_tokenId] == address(0) ? primarySaleRecipient() : saleRecipient[_tokenId])
            : _primarySaleRecipient;

        CurrencyTransferLib.transferCurrency(_currency, msg.sender, _saleRecipient, totalPrice);
    }

    /**
     * @dev Transfers the NFTs being claimed.
     *
     * @param _to                    The address to which the NFTs are being transferred.
     * @param _tokenId               The tokenId of the NFTs being claimed.
     * @param _quantityBeingClaimed  The quantity of NFTs being claimed.
     */
    function transferTokensOnClaim(
        address _to,
        uint256 _tokenId,
        uint256 _quantityBeingClaimed
    ) internal override {
        _mint(_to, _tokenId, _quantityBeingClaimed, "");
        emit TokenPurchased(_to, _tokenId, _quantityBeingClaimed);
    }

    /**
     * @dev Runs before every token transfer / mint / burn.
     *
     * @param operator The address performing the token transfer.
     * @param from     The address from which the token is being transferred.
     * @param to       The address to which the token is being transferred.
     * @param ids      The tokenIds of the tokens being transferred.
     * @param amounts  The amounts of the tokens being transferred.
     * @param data     Any additional data being passed in the token transfer.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    function _canSetPrimarySaleRecipient() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function _canSetClaimConditions() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function _canLazyMint() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function _canReveal() internal view virtual returns (bool) {
        return msg.sender == owner();
    }
}

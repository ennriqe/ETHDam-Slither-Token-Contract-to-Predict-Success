// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title ERC721Whitelisted
 * @dev ERC721 contract with multiple sale rounds and whitelists.
 */
contract ERC721Whitelisted is ERC721, ERC721Burnable, Ownable {
    error InvalidArrayLength();
    error OnlyAdminMinter();
    error AlreadyMintedForAddress();
    error InvalidMerkleProof();
    error MintLimitReached();
    error WrongTimeForGuaranteedRound();
    error WrongTimeForFCFSRound();
    error WrongTimeForPublicRound();

    /**
     * @dev Time parameters for the sale rounds.
     * @param startTime Start time of the round.
     * @param endTime End time of the round.
     */
    struct TimeParams {
        uint128 startTime;
        uint128 endTime;
    }

    /// Time parameters for the guaranteed round.
    TimeParams public guaranteedRound;
    /// Time parameters for the FCFS round.
    TimeParams public fcfsRound;

    /// Start time of the public round.
    uint256 public publicRoundStartTime;
    /// Total general minted tokens.
    uint256 public generalUsedMints;
    /// Maximum number of tokens that can be minted by general users (non-admins).
    uint256 public immutable mintLimitGeneral;

    /// Merkle root for the whitelist.
    bytes32 public merkleRootGuaranteed;
    /// Merkle root for the whitelist.
    bytes32 public merkleRootFCFS;

    /// Next token id to be minted
    uint256 private _nextTokenId;
    /// Base URI for the token metadata
    string private _baseTokenURI;

    /// Mapping of addresses to minted status
    mapping(address => bool) private _guaranteedMinted;
    /// Mapping of addresses to minted status
    mapping(address => bool) private _fcfsMinted;
    /// Mapping of addresses to mint amounts
    mapping(address => uint256) private _adminMintAmounts;
    /// Mapping of addresses to used mint amounts
    mapping(address => uint256) private _adminUsedMints;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        TimeParams memory guaranteedTimeParams,
        TimeParams memory fcfsTimeParams,
        uint256 _publicRoundStartTime,
        uint256 _mintLimit,
        address[] memory adminAddresses,
        uint256[] memory adminMintAmounts
    ) ERC721(name, symbol) Ownable(msg.sender) {
        if (adminAddresses.length != adminMintAmounts.length) revert InvalidArrayLength();

        _baseTokenURI = baseTokenURI;
        guaranteedRound = guaranteedTimeParams;
        fcfsRound = fcfsTimeParams;
        publicRoundStartTime = _publicRoundStartTime;
        mintLimitGeneral = _mintLimit;

        for (uint256 i = 0; i < adminAddresses.length; i++) {
            _adminMintAmounts[adminAddresses[i]] = adminMintAmounts[i];
        }
    }

    /**
     * @dev Sets the time parameters for the guaranteed round.
     * @param startTime Start time of the round.
     * @param endTime End time of the round.
     */
    function setGuaranteedRoundTimeParams(uint128 startTime, uint128 endTime) external onlyOwner {
        guaranteedRound.startTime = startTime;
        guaranteedRound.endTime = endTime;
    }

    /**
     * @dev Sets the time parameters for the FCFS round.
     * @param startTime Start time of the round.
     * @param endTime End time of the round.
     */
    function setFCFSRoundTimeParams(uint128 startTime, uint128 endTime) external onlyOwner {
        fcfsRound.startTime = startTime;
        fcfsRound.endTime = endTime;
    }

    /**
     * @dev Sets the public round start time.
     * @param _publicRoundStartTime Start time of the round.
     */
    function setPublicRoundStartTime(uint256 _publicRoundStartTime) external onlyOwner {
        publicRoundStartTime = _publicRoundStartTime;
    }

    /**
     * @dev Set the merkle root for the guaranteed round whitelist.
     * @param _merkleRoot Merkle root to set.
     */
    function setMerkleRootForGuaranteedRound(bytes32 _merkleRoot) external onlyOwner {
        merkleRootGuaranteed = _merkleRoot;
    }

    /**
     * @dev Set the merkle root for the FCFS round whitelist.
     * @param _merkleRoot Merkle root to set.
     */
    function setMerkleRootForFCFSRound(bytes32 _merkleRoot) external onlyOwner {
        merkleRootFCFS = _merkleRoot;
    }

    /**
     * @dev Mint a token for the admin.
     * @param addressList List of addresses to mint to.
     */
    function safeMintAdmin(address[] calldata addressList) external {
        if (_adminMintAmounts[msg.sender] == 0) revert OnlyAdminMinter();
        uint256 listLength = addressList.length;
        if (_adminUsedMints[msg.sender] + listLength > _adminMintAmounts[msg.sender]) revert MintLimitReached();
        _adminUsedMints[msg.sender] += listLength;

        uint256 tokenId = _nextTokenId;
        _nextTokenId += listLength;
        for (uint256 i = 0; i < listLength; i++) {
            _safeMint(addressList[i], tokenId + i);
        }
    }

    /**
     * @dev Mint a token for the function caller on the guaranteed round.
     * @param proof Merkle proof to verify.
     */
    function safeMintGuaranteedRound(bytes32[] calldata proof) external {
        if (!_verifyMerkleProof(proof, merkleRootGuaranteed, msg.sender)) revert InvalidMerkleProof();
        if (block.timestamp < guaranteedRound.startTime || block.timestamp > guaranteedRound.endTime)
            revert WrongTimeForGuaranteedRound();
        if (_guaranteedMinted[msg.sender]) revert AlreadyMintedForAddress();

        _guaranteedMinted[msg.sender] = true;

        _safeMintGeneral(msg.sender);
    }

    /**
     * @dev Mint a token for the function caller on the FCFS round.
     * @param proof Merkle proof to verify.
     */
    function safeMintFCFSRound(bytes32[] calldata proof) external {
        if (!_verifyMerkleProof(proof, merkleRootFCFS, msg.sender)) revert InvalidMerkleProof();
        if (block.timestamp < fcfsRound.startTime || block.timestamp > fcfsRound.endTime)
            revert WrongTimeForFCFSRound();
        if (_fcfsMinted[msg.sender]) revert AlreadyMintedForAddress();

        _fcfsMinted[msg.sender] = true;

        _safeMintGeneral(msg.sender);
    }

    /**
     * @dev Mint a token for the function caller on the public round.
     */
    function safeMintPublicRound() external {
        if (block.timestamp < publicRoundStartTime) revert WrongTimeForPublicRound();

        _safeMintGeneral(msg.sender);
    }

    /**
     * @dev Mint a token to the given address.
     * @param to Address to mint the token to.
     */
    function _safeMintGeneral(address to) private {
        if (generalUsedMints >= mintLimitGeneral) revert MintLimitReached();
        generalUsedMints++;
        uint256 tokenId = _nextTokenId++;

        _safeMint(to, tokenId);
    }

    /**
     * @dev See {IERC721-_baseURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Verify the merkle proof for the given address.
     * @param proof Merkle proof to verify.
     * @param addressToVerify Address to verify.
     */
    function _verifyMerkleProof(
        bytes32[] calldata proof,
        bytes32 merkleRoot,
        address addressToVerify
    ) private pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addressToVerify));

        return MerkleProof.verifyCalldata(proof, merkleRoot, leaf);
    }
}

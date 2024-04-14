// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//    ░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓███████▓▒░░▒▓████████▓▒░░▒▓███████▓▒░▒▓█▓▒░░▒▓███████▓▒░   //
//   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░          //
//   ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░          //
//   ░▒▓█▓▒▒▓███▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓██████▓▒░  ░▒▓██████▓▒░░▒▓█▓▒░░▒▓██████▓▒░    //
//   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░             ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░   //
//   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░             ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░   //
//    ░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓███████▓▒░░▒▓█▓▒░▒▓███████▓▒░    //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.20;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract GonesisRing is ERC721AUpgradeable, ERC2981Upgradeable, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable {

    uint256 public constant MAX_SUPPLY = 2000;

    uint public mintPrice;

    bool public mintNeedCheckProof;

    uint public mintOpenTimestamp;

    uint public mintCloseTimestamp;

    bytes32 public merkleRoot;

    error TransferNotEnabled();
    error WhiteListNotVerified();
    error MintNotStarted();
    error NotEoaWallet();
    error ExceedMintCountPerWallet();
    error InvalidFunds();
    error ExceedMaxSupply();

    string public baseURI;

    bool public isTransferEnabled;

    modifier whenTransferEnabled() {
        if (!isTransferEnabled) revert TransferNotEnabled();
        _;
    }

    mapping(address => bool) public minted;

    function initialize() public initializer initializerERC721A {
        address msgSender = _msgSender();

        __ERC721A_init("Gonesis Ring", "Gonesis Ring");
        __Ownable_init(msgSender);
        __ERC2981_init();
        __DefaultOperatorFilterer_init();
        _setDefaultRoyalty(msgSender, 500);

        mintPrice = 0.238 ether;
        mintNeedCheckProof = true;
        mintOpenTimestamp = 1709818200;
        mintCloseTimestamp = 1710423000;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setMintPrice(uint value) external onlyOwner {
        mintPrice = value;
    }

    function setMerkleRoot(bytes32 value) external onlyOwner {
        merkleRoot = value;
    }

    function configMint(bool mintNeedCheckProof_, uint mintOpenTimestamp_, uint mintCloseTimestamp_) external onlyOwner {
        mintNeedCheckProof = mintNeedCheckProof_;
        mintOpenTimestamp = mintOpenTimestamp_;
        mintCloseTimestamp = mintCloseTimestamp_;
    }

    function setBaseURI(string memory value) external onlyOwner {
        baseURI = value;
    }

    function setTransferEnabled(bool value) public onlyOwner {
        isTransferEnabled = value;
    }

    function withdraw() external onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "MP: Transfer failed");
    }

    function mint(bytes32[] calldata merkleProof) external payable {
        address msgSender = _msgSender();
        uint blockTimestamp = block.timestamp;

        if (mintNeedCheckProof) {
            bool whiteListVerified = MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msgSender)));
            if (!whiteListVerified) revert WhiteListNotVerified();
        }
        if (blockTimestamp < mintOpenTimestamp || blockTimestamp > mintCloseTimestamp) revert MintNotStarted();

        if (tx.origin != msgSender) revert NotEoaWallet();
        if (minted[msgSender]) revert ExceedMintCountPerWallet();
        if (msg.value != mintPrice) revert InvalidFunds();
        if (_totalMinted() >= MAX_SUPPLY) revert ExceedMaxSupply();

        _safeMint(msgSender, 1);
        minted[msgSender] = true;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override onlyAllowedOperatorApproval(operator) whenTransferEnabled {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) whenTransferEnabled {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) whenTransferEnabled {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) whenTransferEnabled {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) whenTransferEnabled {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721AUpgradeable, ERC2981Upgradeable) returns (bool) {
        return ERC721AUpgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (bytes(baseURI).length == 0) {
            // Build default JSON metadata
            string memory json = string(
                abi.encodePacked(
                    '{',
                    '"name": "Gonesis Ring #', Strings.toString(tokenId), '",',
                    '"image": "https://static-image.nftgo.io/gonesis/nft.gif",',
                    '"animation_url": "https://static-image.nftgo.io/gonesis/nft.mp4"',
                    '}'
                )
            );

            string memory base64Json = Base64.encode(bytes(json));
            return string(abi.encodePacked('data:application/json;base64,', base64Json));
        }
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }
}

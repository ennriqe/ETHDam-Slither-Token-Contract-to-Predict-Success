// SPDX-License-Identifier: AGPL-3.0-or-later

// Twitter/X: https://twitter.com/BundleERC20
// Docs: bundle-finance.gitbook.io/bundlefi

pragma solidity ^0.8.20;

import { EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import { Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IBundle } from "../interfaces/IBundle.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract BundleNFT is Ownable, ReentrancyGuard, ERC721 {
    using SafeERC20 for IBundle;
    using Strings for uint256;
    using Counters for Counters.Counter;
    IBundle public bundleToken;
    
    address private signer;
    mapping(uint256 => string) internal tokenURIs;

    uint16 private mintCount;
    uint256 mintPrice;

    constructor(
        string memory _name,
        string memory _symbol,
        address _bundleToken,
        uint256 _mintPrice
    ) public ERC721(_name, _symbol) {
        signer = _msgSender();
        mintCount = 0;
        bundleToken = IBundle(_bundleToken);
        mintPrice = _mintPrice;
    }

    function setTokenUri(uint256 tokenId, string memory _tokenURI) private {
        tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        return string(
            abi.encodePacked(
            "https://ipfs.io/ipfs/",
            tokenURIs[tokenId]
           )
        );
    }

    function mint(address _to, uint256 _tokenId, uint256 _price, string memory _tokenURI) external {
        require(_price > 0 && _price == mintPrice, "Should have price");
        setTokenUri(_tokenId, _tokenURI);
        bundleToken.safeTransferFrom(msg.sender, address(this), mintPrice);
        bundleToken.burn(mintPrice);
        _mint(_to, _tokenId);
        mintCount ++;
    }

    function getMintCount() public view returns (uint16) {
        return mintCount;
    }

    function getSigner() public view returns (address) {
        return signer;
    }

    function updateSigner(address _signer) external isSigner {
        signer = _signer;
    }

    function updateBundleToken(address _bundleToken) external isSigner {
        bundleToken = IBundle(_bundleToken);
    }

    function updateMintPrice(uint256 _mintPrice) external isSigner {
        mintPrice = _mintPrice;
    }

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    modifier isSigner {
        require(_msgSender() == signer, "This function can only be called by an signer");
        _;
    }
}
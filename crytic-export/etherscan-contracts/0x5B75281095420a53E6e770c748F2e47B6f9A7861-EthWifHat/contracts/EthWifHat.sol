// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EthWifHat is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private supply;

    uint256 public cost;
    uint256 public maxSupply;

    bool public paused = true;

    struct NFTMetadata {
        string ipfsMetadataLink;
    }

    mapping(uint256 => NFTMetadata) private tokenMetadata;

    constructor() ERC721("EthWifHat", "Wef") {
        cost = 0.013 ether;
        maxSupply = 10000;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mint(string memory _ipfsMetadataLink) public payable {
        require(!paused, "The contract is paused!");
        require(supply.current() < maxSupply, "Max supply exceeded!");
        require(msg.value >= cost, "Insufficient funds!");

        supply.increment();
        uint256 newTokenId = supply.current();
        _safeMint(msg.sender, newTokenId);
        tokenMetadata[newTokenId] = NFTMetadata(_ipfsMetadataLink);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenMetadata[tokenId].ipfsMetadataLink;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance must be greater than 0");
        payable(owner()).transfer(balance);
    }
}

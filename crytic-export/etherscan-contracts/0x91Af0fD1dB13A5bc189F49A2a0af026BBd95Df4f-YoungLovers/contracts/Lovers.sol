// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol" as erc721;
import "@openzeppelin/contracts/security/Pausable.sol" as pausable;
import "@openzeppelin/contracts/access/Ownable.sol" as ownable;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol" as erc721Burnable;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol" as ozStrings;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/token/ERC721/ERC721.sol
contract YoungLovers is erc721.ERC721, pausable.Pausable, ownable.Ownable, erc721Burnable.ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public maxSupply = 8888;
    uint256 public cost = 0.025 ether;
    string public baseURI = "ipfs://QmVv91koDekjaMT8eAfC127RMdTG52jaZrLMjEpoJyg173/";

    constructor() erc721.ERC721("Young Lovers Social Club", "YLSC") {
      // Let's start at 1, not 0
      _tokenIdCounter.increment();

      // Mint to nichochar.eth and stelladore.eth
      for(uint i = 0; i < 20; i++) {
        safeMint(0x719695C8FAfeAD68759CcA3895b7C31402CBCC60);
      }
      for(uint i = 0; i < 20; i++) {
        safeMint(0x885F8588bB15a046f71bD5119f5BC3B67ee883d3);
      }
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function mint(address _to, uint256 _count) public whenNotPaused payable {
      require(_count > 0, "you need to mint at least 1");
      require(_tokenIdCounter.current() + _count <= maxSupply, "not enough left to mint");

      if (msg.sender != owner()) {
        require(msg.value >= cost * _count, "not enough ether paid");
      }

      for (uint256 i = 1; i <= _count; i++) {
        safeMint(_to);
      }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }


  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, ozStrings.Strings.toString(tokenId), ".json"))
        : "";
  }
    // only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function withdraw() public payable onlyOwner {
        // get the amount of Ether stored in this contract
    uint amount = address(this).balance;

    // calculate the amount to send to each address (50% each)
    uint splitAmount = amount / 2;

    // send half of the Ether to nichochar.eth
    (bool successA, ) = payable(0x885F8588bB15a046f71bD5119f5BC3B67ee883d3).call{value: splitAmount}("");
    require(successA, "Failed to send Ether to address A");

    // send the other half of the Ether to stelladore.eth
    (bool successB, ) = payable(0x719695C8FAfeAD68759CcA3895b7C31402CBCC60).call{value: splitAmount}("");
    require(successB, "Failed to send Ether to address B");
  }
}

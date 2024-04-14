// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@chocolate-factory/contracts/uri-manager/UriManagerUpgradable.sol';

contract SeizonU is
  Initializable,
  OwnableUpgradeable,
  ERC721Upgradeable,
  UriManagerUpgradable
{
  function initialize(
    string calldata name_,
    string calldata symbol_,
    string calldata prefix_,
    string calldata suffix_
  ) external initializer {
    __Ownable_init();
    __AdminManager_init_unchained();
    __UriManager_init_unchained(prefix_, suffix_);
    __ERC721_init_unchained(name_, symbol_);
  }

  function mint(address to_, uint256 tokenId_) external onlyAdmin {
    _safeMint(to_, tokenId_);
  }

  function tokenURI(
    uint256 tokenId
  ) public view override returns (string memory) {
    _requireMinted(tokenId);
    return _buildUri(tokenId);
  }

  function setApprovalForAll(address, bool) public pure override {
    require(false, 'Soul bound token');
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal override {
    require(from == address(0), 'Soul bound token');
    super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
  }
}

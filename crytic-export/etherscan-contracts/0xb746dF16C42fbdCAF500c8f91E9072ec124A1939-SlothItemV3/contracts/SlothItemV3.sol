//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ISlothItemV5.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/RevokableOperatorFiltererUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";

contract SlothItemV3 is Initializable, ERC721AQueryableUpgradeable, OwnableUpgradeable, ISlothItemV5, IERC2981, RevokableOperatorFiltererUpgradeable {
  mapping(uint256 => IItemTypeV2.ItemType) public itemType;
  mapping(address => uint256) public itemMintCount;
  IItemTypeV2.ItemType private _nextItemType;
  address private _slothMintAddr;
  address payable private _royaltyWallet;
  uint256 public royaltyBasis;
  uint256 public itemSupply;
  string  public baseURI;
  mapping(uint256 => uint256) public tokenIdToItemId;

  function initialize() initializerERC721A initializer public {
    __ERC721A_init("SlothItem", "SLTI");
    __Ownable_init();
    __RevokableOperatorFilterer_init(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true);

    _nextItemType = IItemTypeV2.ItemType.HEAD;
    _royaltyWallet = payable(0x452Ccc6d4a818D461e20837B417227aB70C72B56);
    royaltyBasis = 200; // 2%
  }

  function owner() public view override(OwnableUpgradeable, RevokableOperatorFiltererUpgradeable) returns (address) {
    return super.owner();
  }

  function _clothesMint(address sender, uint256 quantity) private {
    require(msg.sender == _slothMintAddr, "not slothMintAddr");
    uint256 nextTokenId = _nextTokenId();

    _mint(sender, quantity);
    itemType[nextTokenId] = IItemTypeV2.ItemType.CLOTHES;
    _nextTokenId();
  }

  function setSlothMintAddr(address newSlothMintAddr) external onlyOwner {
    _slothMintAddr = newSlothMintAddr;
  }

  function clothesMint(address sender, uint256 quantity) external {
    _clothesMint(sender, quantity);
  }

  function _itemMint(address sender, uint256 quantity) internal {
    require(msg.sender == _slothMintAddr, "not slothMintAddr");
    uint256 nextTokenId = _nextTokenId();

    _mint(sender, quantity);
    for(uint256 i = 0; i < quantity; i++) {
      itemType[nextTokenId] = _nextItemType;
      if (_nextItemType == IItemTypeV2.ItemType.FOOT) {
        _nextItemType = IItemTypeV2.ItemType.CLOTHES;
      }
      _nextItemType = IItemTypeV2.ItemType(uint(_nextItemType) + 1);
      nextTokenId +=1 ;
    }
    itemMintCount[sender] += quantity;
    itemSupply += quantity;
  }

  function itemMint(address sender, uint256 quantity) external {
    _itemMint(sender, quantity);
  }

  function _anyItemMintMulti(address sender, anyItemMintItem[] calldata items) internal {
    uint256 nextTokenId = _nextTokenId();
    _mint(sender, items.length);
    for(uint256 i = 0; i < items.length; i++) {
      itemType[nextTokenId] = items[i].itemType;
      tokenIdToItemId[nextTokenId] = items[i].itemId;
      nextTokenId += 1;
    }
    itemMintCount[sender] += items.length;
    itemSupply += items.length;
  }
  function _anyItemMint(address sender, anyItemMintItem calldata item) internal {
    uint256 nextTokenId = _nextTokenId();
    _mint(sender, 1);
    itemType[nextTokenId] = item.itemType;
    tokenIdToItemId[nextTokenId] = item.itemId;
    itemMintCount[sender] += 1;
    itemSupply += 1;
  }

  function anyItemMintMulti(address sender, anyItemMintItem[] calldata items) external {
    require(msg.sender == _slothMintAddr, "not slothMintAddr");
    _anyItemMintMulti(sender, items);
  }
  function anyItemMint(address sender, anyItemMintItem calldata item) external {
    require(msg.sender == _slothMintAddr, "not slothMintAddr");
    _anyItemMint(sender, item);
  }

  function getItemType(uint256 tokenId) external view returns (IItemTypeV2.ItemType) {
    return itemType[tokenId];
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function exists(uint256 _tokenId) public view returns (bool) {
    return _exists(_tokenId);
  }

  function getItemMintCount(address sender) external view returns (uint256) {
    return itemMintCount[sender];
  }

  function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      override(ERC721AUpgradeable, IERC721AUpgradeable)
      onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721AUpgradeable, IERC165, IERC721AUpgradeable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC165-royaltyInfo}.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    require(_exists(tokenId), "Nonexistent token");
    return (payable(_royaltyWallet), uint((salePrice * royaltyBasis)/10000));
  }
}
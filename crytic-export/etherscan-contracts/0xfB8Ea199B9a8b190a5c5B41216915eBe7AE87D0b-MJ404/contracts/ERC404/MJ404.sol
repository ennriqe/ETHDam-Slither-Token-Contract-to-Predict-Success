//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC404.sol";
import "./Strings.sol";

contract MJ404 is ERC404 {
    error InvalidMintCount();
    error InvalidOwnerBalance();
    error InvalidMintPrice();
    error InvalidMintTime();

    mapping(uint256 => uint32) public attributes;

    bool public mintTime = false;
    uint256 public mintPrice = 0.0404 ether;
    
    mapping(address => uint32) public mintCount;

    uint32 public goldSuffixCount   = 100;
    uint32 public normalSuffixCount = 900;

    uint32 public constant PROP_DIVISOR = 1_0000;
    uint32[] public goldProps       = [1000, 1404];
    uint32[] public propCounts      = [1, 10];

    uint32 public campCount         = 3;
    uint32[] public cardCounts      = [9, 9, 9];

    string public uriPrefix;
    string public uriSuffix = ".json";

    address public _admin;

    uint32 public maxMintCount = 3000;
    uint32 public totalMintCount = 0;
    uint32 public maxPerWallet = 4;

    uint32 public constant MAX_SUPPLY = 4040;

    constructor(address _owner, address _royaltyReceiver) ERC404("Mahjong404", "MJ404", 18, uint256(MAX_SUPPLY), _owner) {
        _admin = _owner;
        royaltyReceiver = _royaltyReceiver;
        balanceOf[_admin] = uint256(MAX_SUPPLY) * 10 ** 18;
        setWhitelist(_admin, true);
        setWhitelist(_royaltyReceiver, true);
    }

    modifier onlyAdmin() {
        require(_admin == msg.sender || owner == msg.sender, "Admin: caller is not the admin");
        _;
    }

    function admin() public view returns (address) {
        return _admin;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        uint32 attr = attributes[id];
        require(attr > 0, "ERC404Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0? string.concat(currentBaseURI, Strings.toString(id), ".", Strings.toString(attr), uriSuffix): '';
    }

    function _baseURI() internal view virtual returns (string memory) {
        return uriPrefix;
    }

    function setAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "Admin: new admin is the zero address");
        _admin = newAdmin;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyAdmin {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyAdmin {
        uriSuffix = _uriSuffix;
    }

    function setSuffixCount(uint32 goldCount, uint32 normalCount) public onlyAdmin {
        goldSuffixCount = goldCount;
        normalSuffixCount = normalCount;
    }

    function setCards(uint32[] memory counts) public onlyAdmin {
        cardCounts = counts;
        campCount = uint32(counts.length);
    }

    function setProp(uint32[] memory props, uint32[] memory counts) public onlyAdmin {
        goldProps  = props;
        propCounts = counts;
    }

    function setMintPrice(uint256 price) public onlyAdmin {
        mintPrice = price;
    }

    function setMaxPerWallet(uint32 maxCount) public onlyAdmin {
        maxPerWallet = maxCount;
    }

    function setMintTime(bool isTime) public onlyAdmin {
        mintTime = isTime;
    }

    function setMaxMint(uint32 maxCount) public onlyAdmin {
        maxMintCount = maxCount;
    }

    function isMintTime() public view returns (bool) {
        return mintTime;
    }

    function setNameSymbol(
        string memory _name,
        string memory _symbol
    ) public onlyAdmin {
        _setNameSymbol(_name, _symbol);
    }

    function royaltyInfo(
        uint256 _salePrice
    ) public view virtual override returns (address, uint256) {
        return (royaltyReceiver, (_salePrice * royaltyFee) / ROYALTY_DIVISOR);
    }

    function setRoyaltyFee(uint256 _royaltyFee) public override onlyAdmin {
        require(_royaltyFee <= ROYALTY_DIVISOR, "ERC404: Royalty fee too high.");
        royaltyFee = _royaltyFee;
    }

    function setRoyaltyReceiver(address _royaltyReceiver) public override onlyAdmin {
        require(_royaltyReceiver != address(0), "ERC404: Invalid receiver address.");
        royaltyReceiver = _royaltyReceiver;
    }

    function withdrawEth(address to) public onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "MJ404: balance is zero");
        payable(to).transfer(balance);
    }

    function balanceEth() public view returns (uint256) {
        return address(this).balance;
    }

    function _random(uint256 tokenId, uint32 number) internal view returns (uint32) {
        return uint32(uint256(keccak256(abi.encodePacked(block.timestamp, block.number, tokenId, msg.sender))) % number);
    }

    function _getGoldProp(uint256 totalCount) internal view returns (uint256) {
        if (totalCount <= 0) {
            return 0;
        }
        for (uint256 i = 0; i < (propCounts.length - 1); i++) {
            if (totalCount >= propCounts[i] && totalCount < propCounts[i + 1]) {
                return goldProps[i];
            }
        }
        return goldProps[propCounts.length - 1];
    }

    function _afterMint(
        uint256 tokenId,
        uint256 totalCount
    ) internal override {
        uint32 prop = _random(tokenId, PROP_DIVISOR);
        // 1: gold; 2: normal
        uint32 quality = prop < _getGoldProp(totalCount)? 1: 2;
        uint32 suffixCount = quality == 1? goldSuffixCount: normalSuffixCount;
        uint32 suffix = _random(tokenId, suffixCount);

        uint32 camp = _random(tokenId, campCount);
        uint32 card = _random(tokenId, cardCounts[camp]);
        uint32 campCard = camp * 10 + card;

        attributes[tokenId] = suffix * 1000 + campCard * 10 + quality;
    }

    function _afterBurn(
        uint256 tokenId
    ) internal override {
        delete attributes[tokenId];
    }

    modifier onlyMintTime() {
        if (!mintTime) {
            revert InvalidMintTime();
        }   
        _;  
    }

    modifier checkPrice(uint256 price, uint256 nftAmount) {
        if (price * nftAmount != msg.value) {
            revert InvalidMintPrice();
        }
        _;
    }

    modifier checkCount(uint32 count) {
        if (count <= 0 || (totalMintCount + count) > maxMintCount || (mintCount[msg.sender] + count) > maxPerWallet) {
            revert InvalidMintCount();
        }
        _;
    }

    function mint(uint32 count) 
        public
        payable 
        onlyMintTime
        checkPrice(mintPrice, uint256(count))
        checkCount(count)
    {
        uint256 amount = uint256(count) * _getUnit();
        if (balanceOf[owner] < amount) {
            revert InvalidOwnerBalance();
        }
        mintCount[msg.sender] += count;
        totalMintCount += count;
        super._transfer(owner, msg.sender, amount);
    }

    function getMintCount(address addr) public view returns (uint32) {
        return mintCount[addr];
    }

    function getTotalMintCount() public view returns (uint256) {
        return totalMintCount;
    }

    function getAttribute(uint256 tokenId) public view returns (uint256) {
        return attributes[tokenId];
    }

    function getOwnerNftCount(address addr) public view returns (uint256) {
        return _owned[addr].length;
    }

    function getOwnerNftList(address addr, uint32 offset, uint32 limit) public view returns (uint256[] memory) {
        if (limit > 20) {
            limit = 20;
        }
        uint32 length = uint32(_owned[addr].length);
        if (offset >= length) {
            return new uint256[](0);
        }
        uint32 count = limit;
        if (length < (offset + limit)) {
            count = length - offset;
        }
        uint256[] storage tokens = _owned[addr];
        uint256[] memory results = new uint256[](count);
        for (uint32 i = offset; i < (offset + limit) && i < length; i ++) {
            results[i - offset] = tokens[i];
        }   
        return results;
    }
}

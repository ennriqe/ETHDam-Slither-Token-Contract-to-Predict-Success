// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import { ERC7616V2Upgradeable } from "./ERC7616/ERC7616V2Upgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC7616 {
    function transferFrom(address from, address to, uint256 amountOrTokenId) external;
}

//   ,--.       ,--.,--.         ,-----.,--. ,--. ,--.
//   `--' ,---. |  ||  |,--. ,--.'--,  /  .'/   |/  .'
//   ,--.| .-. :|  ||  | \  '  /  .'  /  .-.`|  |  .-.
//   |  |\   --.|  ||  |  \   '  /   /\   o ||  \   o |
// .-'  / `----'`--'`--'.-'  /   `--'  `---' `--'`---'
// '---'                `---'
//         https://twitter.com/jelly_erc
//         https://jelly.top/

/// @notice Jelly
contract Jelly7616V2Upgradeable is ERC7616V2Upgradeable {
    string public dataURI;
    string public baseTokenURI;
    string public skinNftTokenURI;
    address public nftAddress;

    // tokenId => attribute
    mapping(uint256 => uint256) public tokenAttributes;
    mapping(address => uint256) public migratedNFTs;
    mapping(address => uint256) public migratedTokens;
    mapping(address => uint256) public claimedSkinNFTs;

    event JellyNftMigrated(address indexed account, uint256 indexed tokenId);
    event JellyTokenMigrated(address indexed account, uint256 amount);

    error NothingToClaim();

    function initialize(address _nftAddress, address _owner) public initializer {
        ERC7616V2Upgradeable.initialize("Jelly", "JELLY", 18, 5000, _owner, 200, true);
        nftAddress = payable(_nftAddress);
    }

    function setDataURI(string memory _dataURI) public onlyOwner {
        dataURI = _dataURI;
    }

    function setTokenURI(string memory _tokenURI) public onlyOwner {
        baseTokenURI = _tokenURI;
    }

    function setSkinNftTokenURI(string memory _skinNftURI) public onlyOwner {
        skinNftTokenURI = _skinNftURI;
    }

    function setNameSymbol(string memory _name, string memory _symbol) public onlyOwner {
        _setNameSymbol(_name, _symbol);
    }

    function claimableSkinNFTs(address account) public view returns (uint256) {
        return migratedNFTs[account] + migratedTokens[account] / _getUnit() - claimedSkinNFTs[account];
    }

    function migrate(uint256[] calldata tokenIds) public payable {
        uint256 nftAmount = tokenIds.length;

        migratedNFTs[msg.sender] += nftAmount;

        for (uint256 i; i < nftAmount; i++) {
            IERC7616(nftAddress).transferFrom(msg.sender, address(this), tokenIds[i]);
            emit JellyNftMigrated(msg.sender, tokenIds[i]);
        }

        _transfer(address(0), msg.sender, nftAmount * _getUnit());
    }

    function migrate(uint256 tokenAmount) public payable {
        migratedTokens[msg.sender] += tokenAmount;
        IERC7616(nftAddress).transferFrom(msg.sender, address(this), tokenAmount);

        emit JellyTokenMigrated(msg.sender, tokenAmount);
        _transfer(address(0), msg.sender, tokenAmount);
    }

    function claimSkinNFTs() public {
        uint256 claiming = claimableSkinNFTs(msg.sender);
        if (claiming == 0) {
            revert NothingToClaim();
        }

        if (claiming > 200) {
            claiming = 200;
        }

        for (uint256 i; i < claiming; i++) {
            uint256 tokenId = minted;
            minted++;

            _ownerOf[tokenId] = msg.sender;

            tokenAttributes[tokenId] = getRandomNumber(tokenId);

            emit Transfer(address(0), msg.sender, tokenId);
        }

        erc721BalanceOf[msg.sender] += claiming;
        claimedSkinNFTs[msg.sender] += claiming;
    }

    function getRandomNumber(uint256 tokenId) internal view returns (uint256) {
        return uint256(blockhash(block.number - 1)) + block.timestamp + tokenId;
    }

    function getAttribute(uint256 seed) private pure returns (string memory) {
        bytes memory seedBytes = abi.encodePacked(seed);

        bytes32 hashResult = keccak256(seedBytes);

        uint256 hashedNumber = uint256(hashResult);

        uint256 random = hashedNumber % 256;

        uint256[] memory weights = new uint256[](9);
        string[] memory colors = new string[](9);

        // total weight is 256;
        weights[0] = 50; // Green
        colors[0] = "Green";

        weights[1] = 40; // Orange
        colors[1] = "Orange";

        weights[2] = 35; // Red
        colors[2] = "Red";

        weights[3] = 31; // Pink
        colors[3] = "Pink";

        weights[4] = 30; // Blue
        colors[4] = "Blue";

        weights[5] = 25; // Teal
        colors[5] = "Teal";

        weights[6] = 20; // Purple
        colors[6] = "Purple";

        weights[7] = 15; // Lavender
        colors[7] = "Lavender";

        weights[8] = 10; // Gold
        colors[8] = "Gold";

        uint256 sum = 0;

        for (uint256 i = 0; i < weights.length; i++) {
            sum += weights[i];
            if (random < sum) {
                return colors[i];
            }
        }

        revert("Invalid random number provided.");
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        bool split = isSplit(id); // Call isSplit to determine if the token is split

        if (bytes(baseTokenURI).length > 0) {
            return string.concat(baseTokenURI, Strings.toString(id));
        } else {
            uint256 seed = tokenAttributes[id];
            string memory color = getAttribute(seed);

            string memory splitString = split ? "true" : "false"; // Convert bool to string

            // Modify file name based on split
            string memory filename =
                split ? string.concat(dataURI, color, "-split.jpg") : string.concat(dataURI, color, ".jpg");

            string memory jsonPreImage = string.concat(
                string.concat(
                    string.concat('{"name": "Jelly #', Strings.toString(id)),
                    '","description":"A collection of 5,000 Replicants enabled by ERC7616, an experimental token standard.","external_url":"https://jelly.top","image":"'
                ),
                filename
            );

            string memory jsonAttributes = string.concat(
                string.concat(
                    ', "attributes":[',
                    '{"trait_type":"Color","value":"',
                    color,
                    '"},',
                    '{"trait_type":"isSplit","value":"',
                    splitString,
                    '"}'
                ),
                "]}"
            );

            return string.concat("data:application/json;utf8,", string.concat(jsonPreImage, jsonAttributes));
        }
    }

    fallback() external payable { }

    receive() external payable { }
}

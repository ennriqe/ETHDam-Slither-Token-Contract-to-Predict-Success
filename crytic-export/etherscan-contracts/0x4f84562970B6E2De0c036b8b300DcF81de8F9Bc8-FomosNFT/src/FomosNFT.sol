// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// openzepplin v5.0.1
contract FomosNFT is ERC721, Ownable(msg.sender) {
    address public mintingContract;

    uint256 public tokenId;
    mapping(uint256 => uint256) public tokenIdToPeriodId;

    constructor() ERC721("nofomoNFT", "nofomoNFT") {}

    modifier onlyAuthrizedContract() {
        require(msg.sender == mintingContract, "only minting contract can mint");
        _;
    }

    function mint(address to, uint256 amount, uint256 periodId)
        external
        onlyAuthrizedContract
        returns (uint256[] memory tokenIds)
    {
        tokenIds = _batchMint(to, amount, periodId);
    }

    function _batchMint(address to, uint256 amount, uint256 periodId) internal returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            tokenId++;
            tokenIdToPeriodId[tokenId] = periodId;
            tokenIds[i] = tokenId;
            _mint(to, tokenId);
        }
    }

    function getPeriodIdByTokenId(uint256 _tokenId) external view returns (uint256) {
        return tokenIdToPeriodId[_tokenId];
    }

    function setMintingContract(address _mintingContract) external onlyOwner {
        mintingContract = _mintingContract;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        revert("NoFomoNFT: transfer not allowed");
    }
}

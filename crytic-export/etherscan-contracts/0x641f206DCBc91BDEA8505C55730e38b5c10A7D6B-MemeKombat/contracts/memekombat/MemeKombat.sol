// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "../lib/ERC721/ERC721Preset.sol";

/**
 * @title Meme Kombat NFT
 * @dev ERC721 contract for https://memekombat.io
 * @custom:version v1.0
 * @custom:date 7 March 2024
 */
contract MemeKombat is ERC721Preset {
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");

    constructor() ERC721Preset("Meme Kombat", "MK") {
        _grantRole(MINT_ROLE, msg.sender);
    }

    function safeMint(address to) external onlyRole(MINT_ROLE) returns (uint256 tokenId) {
        tokenId = _safeMint(to);
        return tokenId;
    }
}

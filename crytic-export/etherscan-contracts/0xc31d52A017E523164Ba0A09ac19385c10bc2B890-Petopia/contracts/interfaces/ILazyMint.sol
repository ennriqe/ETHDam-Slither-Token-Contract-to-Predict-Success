// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILazyMint {
    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI);
}

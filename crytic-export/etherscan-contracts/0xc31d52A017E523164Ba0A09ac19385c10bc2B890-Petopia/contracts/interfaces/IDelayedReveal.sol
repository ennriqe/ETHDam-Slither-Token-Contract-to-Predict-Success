// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelayedReveal {
    event TokenURIRevealed(uint256 indexed index, string revealedURI);

    function reveal(uint256 identifier, bytes calldata key) external returns (string memory revealedURI);

    function encryptDecrypt(bytes memory data, bytes calldata key) external pure returns (bytes memory result);
}

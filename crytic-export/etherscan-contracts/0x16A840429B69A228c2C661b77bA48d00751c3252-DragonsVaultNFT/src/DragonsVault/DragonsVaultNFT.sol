/*
 * SPDX-License-Identifier: MIT
 *
 * Dragon's Vault Token
 *
 * https://dragonsvault.fi
 * https://t.me/Dragons_Vault
 * https://twitter.com/DragonVaultSol
 */

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DragonsVaultNFT is ERC721, ERC721Enumerable, AccessControl {
    uint256 private _nextTokenId = 1;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string public BASE_URI = 'ipfs://bafybeiftc26w4jmy4uqn2yifzinspwiyo6erbymwjzfzeyzupqwnjgbu7a/';

    constructor() ERC721("Dragon's Vault", "Dragon") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setBaseURI(string memory baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        BASE_URI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    // Function to grant minter role to other addresses
    function grantMinterRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, account);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    // Function to revoke minter role from addresses
    function revokeMinterRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, account);
    }

}

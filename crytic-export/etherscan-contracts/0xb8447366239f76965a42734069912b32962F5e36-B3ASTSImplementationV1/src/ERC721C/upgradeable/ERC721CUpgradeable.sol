// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {
    CreatorTokenBaseUpgradeable,
    ICreatorToken,
    TransferSecurityLevels,
    ICreatorTokenTransferValidator
} from "./CreatorTokenBaseUpgradeable.sol";
import {ERC721Upgradeable} from "openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";

/**
 * @title ERC721CInitializable
 * @author Limit Break, Inc.
 * @notice Initializable implementation of ERC721C to allow for EIP-1167 proxy clones.
 */
abstract contract ERC721CUpgradeable is ERC721Upgradeable, CreatorTokenBaseUpgradeable {
    function __ERC721C_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init(name_, symbol_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICreatorToken).interfaceId || super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        _validateBeforeTransfer(from, to, tokenId);
        return super._update(to, tokenId, auth);
    }
}

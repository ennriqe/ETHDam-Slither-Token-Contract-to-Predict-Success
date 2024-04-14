// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract WithdrawVFExtension is Context, ReentrancyGuard {
    constructor() {}

    /**
     * @dev Withdraw balance on contact to msg sender
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function _withdrawMoney() internal nonReentrant {
        address payable to = payable(_msgSender());
        Address.sendValue(to, address(this).balance);
    }

    /**
     * @dev Withdraw token if we need to refund
     *
     * Requirements:
     *
     * - `contractAddress` must support the IVFToken interface
     * - the caller must be an admin role
     */
    function _withdrawToken(
        address contractAddress,
        address to,
        uint256 tokenId
    ) internal nonReentrant {
        IERC721(contractAddress).transferFrom(address(this), to, tokenId);
    }
}

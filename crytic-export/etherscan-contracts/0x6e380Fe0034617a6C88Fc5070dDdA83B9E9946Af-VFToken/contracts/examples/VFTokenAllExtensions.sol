// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {AccessControlVFExtension} from "../extensions/accesscontrol/AccessControlVFExtension.sol";
import {RoyaltiesVFExtension} from "../extensions/royalties/RoyaltiesVFExtension.sol";
import {WithdrawVFExtension} from "../extensions/withdraw/WithdrawVFExtension.sol";
import {OwnableVFExtension} from "../extensions/accesscontrol/OwnableVFExtension.sol";

abstract contract VFTokenAllExtensions is
    AccessControlVFExtension,
    RoyaltiesVFExtension,
    WithdrawVFExtension,
    OwnableVFExtension
{
    constructor(
        address controlContractAddress,
        address royaltiesContractAddress,
        address initialOwner
    )
        AccessControlVFExtension(controlContractAddress)
        RoyaltiesVFExtension(royaltiesContractAddress)
        OwnableVFExtension(initialOwner)
    {}

    function setRoyaltiesContract(
        address royaltiesContractAddress
    ) external onlyRole(getAdminRole()) {
        super._setRoyaltiesContract(royaltiesContractAddress);
    }

    function withdrawMoney() external onlyRole(getAdminRole()) {
        super._withdrawMoney();
    }

    function withdrawToken(
        address contractAddress,
        address to,
        uint256 tokenId
    ) external onlyRole(getAdminRole()) {
        super._withdrawToken(contractAddress, to, tokenId);
    }
}

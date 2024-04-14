// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {OwnableUpgradeable, ContextUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {
    ERC721CUpgradeable,
    TransferSecurityLevels,
    ICreatorTokenTransferValidator
} from "./ERC721C/upgradeable/ERC721CUpgradeable.sol";
import {ERC2981Upgradeable} from "openzeppelin-upgradeable/token/common/ERC2981Upgradeable.sol";

library B3ASTSStorage {
    struct Layout {
        bool hasSetup;
        uint256 operatorWhitelistID;
        string baseURI;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("B3ASTSImpl.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

contract B3ASTSImplementationV1 is OwnableUpgradeable, ERC721CUpgradeable, ERC2981Upgradeable {
    error ErrAlreadySetup();
    error ErrNotOwner();
    error ErrInvalidTokenID();

    address constant VALIDATOR_ADDRESS = 0x0000721C310194CcfC01E523fc93C9cCcFa2A0Ac;

    function initialize() external initializer {
        __Ownable_init(tx.origin);
        __ERC721C_init("B3L B3ASTS", "B3ASTS");
        __ERC2981_init();
        _setDefaultRoyalty(tx.origin, 500);
    }

    //
    function setupValidator() external onlyOwner {
        if (B3ASTSStorage.layout().hasSetup) {
            revert ErrAlreadySetup();
        }
        B3ASTSStorage.layout().hasSetup = true;

        ICreatorTokenTransferValidator v = ICreatorTokenTransferValidator(VALIDATOR_ADDRESS);
        uint256 _operatorWhitelistID = v.createOperatorWhitelist("B3ASTS");
        B3ASTSStorage.layout().operatorWhitelistID = _operatorWhitelistID;
        v.addOperatorToWhitelist(uint120(_operatorWhitelistID), 0x0000000000000000000000000000000000000000);
        setToCustomValidatorAndSecurityPolicy(address(v), TransferSecurityLevels.One, uint120(_operatorWhitelistID), 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        B3ASTSStorage.layout().baseURI = baseURI_;
    }

    /**
     * @dev Sets the default recommended creator royalty according to ERC2981
     * @param receiver The address for royalties to be sent to
     * @param feeNumerator Royalty in basis point (e.g. 1 == 0.01%, 500 == 5%)
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    struct Holder {
        address addr;
        uint256 tokenID;
    }

    /**
     * @dev Airdrop holders based on snapshot
     * @param holders_ Array of holders to airdrop
     */
    function airdrop(Holder[] memory holders_) external onlyOwner {
        // loop holders
        for (uint256 i = 0; i < holders_.length;) {
            Holder memory __holder = holders_[i];
            if (__holder.tokenID > 1000 || __holder.tokenID == 0) revert ErrInvalidTokenID();
            _mint(__holder.addr, __holder.tokenID);
            unchecked {
                i++;
            }
        }
    }

    function addToWhitelist(address[] memory addrs_) external onlyOwner {
        ICreatorTokenTransferValidator v = ICreatorTokenTransferValidator(VALIDATOR_ADDRESS);
        for (uint256 i = 0; i < addrs_.length;) {
            v.addOperatorToWhitelist(uint120(B3ASTSStorage.layout().operatorWhitelistID), addrs_[i]);
            unchecked {
                i++;
            }
        }
    }

    function removeFromWhitelist(address[] memory addrs_) external onlyOwner {
        ICreatorTokenTransferValidator v = ICreatorTokenTransferValidator(VALIDATOR_ADDRESS);
        for (uint256 i = 0; i < addrs_.length;) {
            v.removeOperatorFromWhitelist(uint120(B3ASTSStorage.layout().operatorWhitelistID), addrs_[i]);
            unchecked {
                i++;
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function operatorWhitelistID() external view returns (uint256) {
        return B3ASTSStorage.layout().operatorWhitelistID;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  overrides                                 */
    /* -------------------------------------------------------------------------- */
    // creatorTokenBase overrides
    function _requireCallerIsContractOwner() internal view override {
        if (msg.sender != owner()) {
            revert ErrNotOwner();
        }
    }

    // erc721 overrides
    function _baseURI() internal view virtual override returns (string memory) {
        return B3ASTSStorage.layout().baseURI;
    }

    // erc165 overrides
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721CUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return ERC721CUpgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }
}

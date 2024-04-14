// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "../token/ERC721VF.sol";
import "./VFTokenAllExtensions.sol";

contract VFToken is ERC721VF, VFTokenAllExtensions {
    //Token base URI
    string private _baseUri;

    /**
     * @dev Initializes the contract by setting a `initialBaseUri`, `name`, `symbol`,
     * and a `controlContractAddress` to the token collection.
     */
    constructor(
        string memory initialBaseUri,
        string memory name,
        string memory symbol,
        address controlContractAddress,
        address royaltiesContractAddress
    )
        ERC721VF(name, symbol)
        VFTokenAllExtensions(
            controlContractAddress,
            royaltiesContractAddress,
            _msgSender()
        )
    {
        string memory contractAddress = Strings.toHexString(
            uint160(address(this)),
            20
        );
        setBaseURI(
            string(
                abi.encodePacked(initialBaseUri, contractAddress, "/tokens/")
            )
        );
    }

    /**
     * @dev Get the base token URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    /**
     * @dev Update the base token URI
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function setBaseURI(string memory baseUri) public onlyRole(getAdminRole()) {
        _baseUri = baseUri;
    }

    /**
     * @dev Permanently lock minting
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function lockMintingPermanently() external onlyRole(getAdminRole()) {
        _lockMintingPermanently();
    }

    /**
     * @dev Set the active/inactive state of minting
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function toggleMintActive() external onlyRole(getAdminRole()) {
        _toggleMintActive();
    }

    /**
     * @dev Set the active/inactive state of burning
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function toggleBurnActive() external onlyRole(getAdminRole()) {
        _toggleBurnActive();
    }

    /**
     * @dev Airdrop `addresses` for `quantity` starting at `startTokenId`
     *
     * Requirements:
     *
     * - the caller must be a minter role
     * - minting must not be locked and must be active
     * - `addresses` and `quantities` must have the same length
     */
    function airdrop(
        address[] calldata addresses,
        uint256[] calldata quantities,
        uint256 startTokenId
    ) external onlyRoles(getMinterRoles()) notLocked mintActive {
        _airdrop(addresses, quantities, startTokenId);
    }

    /**
     * @dev mint batch `to` for `quantity` starting at `startTokenId`
     *
     * Requirements:
     *
     * - the caller must be a minter role
     * - minting must not be locked and must be active
     */
    function mintBatch(
        address to,
        uint8 quantity,
        uint256 startTokenId
    ) external onlyRoles(getMinterRoles()) notLocked mintActive {
        _mintBatch(to, quantity, startTokenId);
    }

    /**
     * @dev mint `to` token `tokenId`
     *
     * Requirements:
     *
     * - the caller must be a minter role
     * - minting must not be locked and must be active
     */
    function mint(
        address to,
        uint256 tokenId
    ) external onlyRoles(getMinterRoles()) notLocked mintActive {
        _mint(to, tokenId);
    }

    /**
     * @dev burn `from` token `tokenId`
     *
     * Requirements:
     *
     * - the caller must be a burner role
     * - burning must be active
     */
    function burn(
        address from,
        uint256 tokenId
    ) external onlyRole(getBurnerRole()) burnActive {
        _burn(from, tokenId, false);
    }
}

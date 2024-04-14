// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**************************************************************\
 * TokenFacetLib v0.3 authored by @0xJonesDev
 * 
 * This contract has been written specifically for
 * GivingGarden by makeitrad x 0xJones
 * 
 * TokenFacetLib is designed to work in conjunction with
 * TokenFacet - it facilitates diamond storage and shared
 * functionality associated with TokenFacet.
/**************************************************************/

import "erc721a-upgradeable/contracts/ERC721AStorage.sol";

library TokenFacetLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("tokenfacet.storage");

    struct state {
        string imageBaseUrl;
        string animBaseUrl;
        mapping(uint256 => uint256) originIndex;
        mapping(uint256 => uint256) origin;
        mapping(uint256 => uint256[]) descendants;
        mapping(uint256 => bool) locked;
        bool givingAllowed;
        uint256 maxOrigins;
        uint256 originsMinted;
        uint256 unitPrice;
        bool saleActive;
    }

    event give(uint256 parentTokenId, uint256 childTokenId, uint256 generation);
    event MetadataUpdate(uint256 _tokenId);

    /**
     * @dev Return stored state struct.
     */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }
}

/**************************************************************\
 * TokenFacet v0.3 authored by @0xJonesDev
 * 
 * This facet contract has been written specifically for
 * GivingGarden by makeitrad x 0xJones
/**************************************************************/

import {GlobalState} from "../libraries/GlobalState.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

contract TokenFacet is ERC721AUpgradeable {
    // VARIABLE GETTERS //

    function givingAllowed() external view returns (bool) {
        return TokenFacetLib.getState().givingAllowed;
    }

    function maxOrigins() external view returns (uint256) {
        return TokenFacetLib.getState().maxOrigins;
    }

    function originsMinted() external view returns (uint256) {
        return TokenFacetLib.getState().originsMinted;
    }

    function unitPrice() external view returns (uint256) {
        return TokenFacetLib.getState().unitPrice;
    }

    function saleActive() external view returns (bool) {
        return TokenFacetLib.getState().saleActive;
    }

    // SETUP & ADMIN FUNCTIONS //

    modifier restricted() {
        GlobalState.requireCallerIsAdmin();
        _;
    }

    modifier whenNotPaused() {
        GlobalState.requireContractIsNotPaused();
        _;
    }

    function toggleGivingStatus() external restricted {
        TokenFacetLib.getState().givingAllowed = !TokenFacetLib
            .getState()
            .givingAllowed;
    }

    function setImageBaseUrl(string memory url) external restricted {
        TokenFacetLib.getState().imageBaseUrl = url;
    }

    function setAnimBaseUrl(string calldata url) external restricted {
        TokenFacetLib.getState().animBaseUrl = url;
    }

    function setMaxOrigins(uint256 max) external restricted {
        TokenFacetLib.getState().maxOrigins = max;
    }

    function setUnitPrice(uint256 price) external restricted {
        TokenFacetLib.getState().unitPrice = price;
    }

    function setSaleActive(bool active) external restricted {
        TokenFacetLib.getState().saleActive = active;
    }

    function reserve(uint256 amount, address recipient) external restricted {
        _mintOrigins(amount, recipient);
    }

    // PUBLIC FUNCTIONS //

    function mint(uint256 amount) external payable whenNotPaused {
        TokenFacetLib.state storage s = TokenFacetLib.getState();
        require(s.saleActive, "TokenFacet: sale is not active");
        require(
            msg.value == amount * s.unitPrice,
            "TokenFacet: incorrect amount of ether sent"
        );
        require(
            s.originsMinted + amount <= s.maxOrigins,
            "TokenFacet: maximum origin tokens reached"
        );

        payable(0x751080E41db1Ab5382AC8E60729a3a8Eaf223ea0).transfer(
            msg.value / 2
        );
        payable(0x806A5B6F56907E0B0a7A178E6866636216123011).transfer(
            msg.value / 2
        );
        _mintOrigins(amount, msg.sender);
    }

    function give(uint256 tokenId, address recipient) external whenNotPaused {
        TokenFacetLib.state storage s = TokenFacetLib.getState();

        uint256 o = origin(tokenId);

        require(s.givingAllowed, "TokenFacet: giving is not allowed now");
        require(
            ownerOf(tokenId) == _msgSenderERC721A(),
            "TokenFacet: you must own a token to give it"
        );
        require(
            recipient != msg.sender,
            "TokenFacet: you may not give to yourself"
        );
        require(
            s.descendants[o].length == 0 ||
                tokenId == s.descendants[o][s.descendants[o].length - 1],
            "TokenFacet: this token may not be given"
        );
        require(
            !locked(tokenId),
            "TokenFacet: this token cannot be given because its origin token has been locked"
        );
        require(
            s.descendants[o].length < 3,
            "TokenFacet: this token has already been given the maximum number of times"
        );

        uint256 newTokenId = _nextTokenId();
        s.origin[newTokenId] = o;
        s.descendants[o].push(newTokenId);

        _mint(recipient, 1);

        emit TokenFacetLib.MetadataUpdate(o);
        emit TokenFacetLib.MetadataUpdate(newTokenId);
        emit TokenFacetLib.give(tokenId, newTokenId, s.descendants[o].length);
    }

    function lock(uint256 tokenId) external whenNotPaused {
        TokenFacetLib.state storage s = TokenFacetLib.getState();
        require(
            ownerOf(tokenId) == _msgSenderERC721A(),
            "TokenFacet: you must own a token to lock it"
        );
        require(!s.locked[tokenId], "TokenFacet: token is already locked");
        require(
            origin(tokenId) == tokenId,
            "TokenFacet: only origin tokens may be locked"
        );

        s.locked[tokenId] = true;
    }

    function burn(uint256 tokenId) external whenNotPaused {
        _burn(tokenId, true);
    }

    // METADATA & MISC FUNCTIONS //

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function tokensOfOwner(
        address owner
    ) public view virtual returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function origin(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "TokenFacet: provided token does not exist");
        TokenFacetLib.state storage s = TokenFacetLib.getState();
        return s.origin[tokenId] == 0 ? tokenId : s.origin[tokenId];
    }

    function descendants(
        uint256 tokenId
    ) external view returns (uint256[] memory) {
        require(
            origin(tokenId) == tokenId,
            "TokenFacet: provided token is not origin"
        );
        return TokenFacetLib.getState().descendants[tokenId];
    }

    function originsOfOwner(
        address owner
    ) external view returns (uint256[] memory) {
        uint256[] memory tokens = tokensOfOwner(owner);
        uint256[] memory origins = new uint256[](tokens.length);

        uint256 count;

        for (uint256 i; i < tokens.length; i++) {
            if (origin(tokens[i]) == tokens[i]) {
                origins[count] = tokens[i];
                count++;
            }
        }

        uint256[] memory filteredOrigins = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            filteredOrigins[i] = origins[i];
        }

        return filteredOrigins;
    }

    function locked(uint256 tokenId) public view returns (bool) {
        return TokenFacetLib.getState().locked[origin(tokenId)];
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        super.tokenURI(tokenId);

        TokenFacetLib.state storage s = TokenFacetLib.getState();

        string memory o = _toString(origin(tokenId));
        string memory oI = _toString(s.originIndex[origin(tokenId)]);
        string memory g = _toString(_generation(tokenId));

        return
            string(
                abi.encodePacked(
                    "data:application/json;utf8,{",
                    '"name": "Plant #',
                    _toString(tokenId),
                    '",',
                    '"description": "Your plant - give it away to watch it grow. Visit https://givinggarden.xyz to give your plant, or lock its metadata.",',
                    '"created_by": "0xJones & makeitrad",',
                    '"image": "',
                    s.imageBaseUrl,
                    oI,
                    "-",
                    g,
                    '.png",',
                    '"animation": "',
                    s.animBaseUrl,
                    oI,
                    "-",
                    g,
                    '.mp4",',
                    '"animation_url": "',
                    s.animBaseUrl,
                    oI,
                    "-",
                    g,
                    '.mp4",',
                    '"attributes":[',
                    '{"trait_type":"Generation","value":"',
                    g,
                    '"},',
                    '{"trait_type":"Origin","value":"',
                    o,
                    '"}',
                    "]}"
                )
            );
    }

    function _generation(uint256 tokenId) internal view returns (uint256) {
        TokenFacetLib.state storage s = TokenFacetLib.getState();
        uint256[] storage d = s.descendants[origin(tokenId)];

        if (origin(tokenId) == tokenId) return d.length + 1;

        for (uint8 i = 0; i < d.length; i++) {
            if (d[i] == tokenId) {
                return d.length - uint256(i);
            }
        }

        revert("TokenFacet: generation not found for provided token");
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _mintOrigins(uint256 amount, address recipient) internal {
        TokenFacetLib.state storage s = TokenFacetLib.getState();

        uint256 oIndex = s.originsMinted;
        for (uint256 i; i < amount; i++) {
            oIndex++;
            s.originIndex[_nextTokenId() + i] = oIndex;
        }

        s.originsMinted += amount;
        _mint(recipient, amount);
    }
}

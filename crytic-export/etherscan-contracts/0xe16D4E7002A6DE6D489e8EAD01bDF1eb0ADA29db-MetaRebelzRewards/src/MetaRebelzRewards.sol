// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC1155P} from "erc1155p/ERC1155P.sol";
import {LibString} from "solady/utils/LibString.sol";
import {OwnableRoles} from "solady/auth/OwnableRoles.sol";
import {IOperatorRegistry} from "./interfaces/IOperatorRegistry.sol";

contract MetaRebelzRewards is ERC1155P, OwnableRoles {
    using LibString for uint256;

    uint256 public constant MINTER_ROLE = _ROLE_0;
    uint256 public constant BURNER_ROLE = _ROLE_1;

    string private _baseUri;
    IOperatorRegistry public operatorRegistry;

    mapping(uint256 => string) private _tokenUris;

    constructor(address _operatorRegistry, string memory baseUri) {
        _initializeOwner(tx.origin);
        operatorRegistry = IOperatorRegistry(_operatorRegistry);
        _baseUri = baseUri;
    }

    function name() public pure override returns (string memory) {
        return "MetaRebelz Rewards";
    }

    function symbol() public pure override returns (string memory) {
        return "RWDZ";
    }

    function uri(uint256 id) public view override returns (string memory) {
        string memory overrideUri = _tokenUris[id];
        if (bytes(overrideUri).length > 0) {
            return overrideUri;
        }
        return string(abi.encodePacked(_baseUri, id.toString()));
    }

    function setBaseUri(string memory baseUri) external onlyOwner {
        _baseUri = baseUri;
    }

    function setTokenUri(uint256 id, string memory tokenUri) external onlyOwner {
        _tokenUris[id] = tokenUri;
    }

    function setOperatorRegistry(address _operatorRegistry) external onlyOwner {
        operatorRegistry = IOperatorRegistry(_operatorRegistry);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external onlyRoles(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external onlyRoles(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(address account, uint256 id, uint256 amount) external onlyRoles(BURNER_ROLE) {
        _ensureApprovedSender(account);
        _burn(account, id, amount);
    }

    function burnBatch(address account, uint256[] calldata ids, uint256[] calldata amounts) external onlyRoles(BURNER_ROLE) {
        _ensureApprovedSender(account);
        _burnBatch(account, ids, amounts);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        if (approved) {
            _ensureAllowedOperator(operator, msg.sender);
        }
        super.setApprovalForAll(operator, approved);
    }

    function _ensureApprovedSender(address from) private view {
        if (!isApprovedForAll(from, msg.sender)) _revert(TransferCallerNotOwnerNorApproved.selector);
    }

    function _beforeTokenTransfer(address operator, address from, address, uint256, uint256, bytes memory) internal view override {
        _ensureAllowedOperator(operator, from);
    }

    function _beforeBatchTokenTransfer(address operator, address from, address, uint256[] calldata, uint256[] calldata, bytes memory) internal view override {
        _ensureAllowedOperator(operator, from);
    }

    function _ensureAllowedOperator(address operator, address from) private view {
        if (operator != address(0)) {
            if (address(operatorRegistry) != address(0)) {
                if (!operatorRegistry.isAllowedOperator(operator, from)) {
                    revert IOperatorRegistry.OperatorNotAllowed();
                }
            }
        }
    }
}
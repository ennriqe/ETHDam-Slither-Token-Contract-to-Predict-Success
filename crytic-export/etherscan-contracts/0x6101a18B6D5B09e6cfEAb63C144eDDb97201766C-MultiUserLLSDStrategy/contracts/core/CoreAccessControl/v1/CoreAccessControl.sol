// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { AccessControl as OZAccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ICoreAccessControlV1 } from "./ICoreAccessControlV1.sol";
import { AccountNotAdmin, AccountNotWhitelisted, AccountMissingRole } from "../../libraries/DefinitiveErrors.sol";

struct CoreAccessControlConfig {
    address admin;
    address definitiveAdmin;
    address[] definitive;
    address[] client;
}

abstract contract CoreAccessControl is ICoreAccessControlV1, OZAccessControl {
    // roles
    bytes32 public constant ROLE_DEFINITIVE = keccak256("DEFINITIVE");
    bytes32 public constant ROLE_DEFINITIVE_ADMIN = keccak256("DEFINITIVE_ADMIN");
    bytes32 public constant ROLE_CLIENT = keccak256("CLIENT");

    // keccak256("HANDLER_MANAGER")
    bytes32 internal constant ROLE_HANDLER_MANAGER = 0xb2b11089d67559292849a1467a255e145c674dd358427860d2c8f589cfbd7aa2;

    modifier onlyDefinitive() {
        _checkRole(ROLE_DEFINITIVE);
        _;
    }
    modifier onlyDefinitiveAdmin() {
        _checkRole(ROLE_DEFINITIVE_ADMIN);
        _;
    }
    modifier onlyClients() {
        _checkRole(ROLE_CLIENT);
        _;
    }
    modifier onlyClientAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier onlyHandlerManager() {
        _checkRole(ROLE_HANDLER_MANAGER);
        _;
    }

    // default admin + definitive admin
    modifier onlyAdmins() {
        bool isAdmins = (hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(ROLE_DEFINITIVE_ADMIN, _msgSender()));

        if (!isAdmins) {
            revert AccountNotAdmin(_msgSender());
        }
        _;
    }
    // client + definitive
    modifier onlyWhitelisted() {
        bool isWhitelisted = (hasRole(ROLE_CLIENT, _msgSender()) || hasRole(ROLE_DEFINITIVE, _msgSender()));

        if (!isWhitelisted) {
            revert AccountNotWhitelisted(_msgSender());
        }
        _;
    }

    constructor(CoreAccessControlConfig memory cfg) {
        // admin
        _grantRole(DEFAULT_ADMIN_ROLE, cfg.admin);
        _grantRole(ROLE_HANDLER_MANAGER, cfg.definitiveAdmin);
        _grantRole(ROLE_HANDLER_MANAGER, cfg.admin);

        // definitive admin
        _grantRole(ROLE_DEFINITIVE_ADMIN, cfg.definitiveAdmin);
        _setRoleAdmin(ROLE_DEFINITIVE_ADMIN, ROLE_DEFINITIVE_ADMIN);

        // definitive
        uint256 cfgDefinitiveLength = cfg.definitive.length;
        for (uint256 i; i < cfgDefinitiveLength; ) {
            _grantRole(ROLE_DEFINITIVE, cfg.definitive[i]);
            unchecked {
                ++i;
            }
        }
        _setRoleAdmin(ROLE_DEFINITIVE, ROLE_DEFINITIVE_ADMIN);

        // clients - implicit role admin is DEFAULT_ADMIN_ROLE
        uint256 cfgClientLength = cfg.client.length;
        for (uint256 i; i < cfgClientLength; ) {
            _grantRole(ROLE_CLIENT, cfg.client[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _checkRole(bytes32 role, address account) internal view virtual override {
        if (!hasRole(role, account)) {
            revert AccountMissingRole(account, role);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "openzeppelin-contracts-upgradeable-v4.9.5/contracts/utils/structs/EnumerableSetUpgradeable.sol";
import {MintOperationArrays} from "../library/MintOperationArray.sol";
import {MintPoolArrays} from "../library/MintPoolArray.sol";
import {ProofOfReserve} from "../library/ProofOfReserve.sol";
import {Redemption} from "../library/Redemption.sol";

/**
 * Defines the storage layout of the token implementation contract. Any
 * newly declared state variables in future upgrades should be appended
 * to the bottom. Never remove state variables from this list, however variables
 * can be renamed. Please add _Deprecated to deprecated variables.
 */
contract ProxyStorage {
    // Initializable
    uint8 _initialized;
    bool _initializing;

    // ContextUpgradeable
    uint256[50] __gap0;

    // ERC20Upgradeable
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    uint256 _totalSupply;
    string __DEPRECATED_name;
    string __DEPRECATED_symbol;
    uint256[45] __gap1;

    // ERC20BurnableUpgradeable
    uint256[50] __gap2;

    // BaseVerifyUpgradeableV1
    address __DEPRECATED_config;
    uint256[50] __gap3;

    // GBPT
    address __DEPRECATED_IssueToAddress;
    bool __DEPRECATED_paused;
    mapping(address => bool) __DEPRECATED_blacklisted;

    // ERC165Upgradeable
    uint256[50] __gap4;

    // AccessControlUpgradeable
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) _roles;
    uint256[49] __gap5;

    // AccessControlEnumerableUpgradeable
    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) _roleMembers;
    uint256[49] __gap6;

    // ERC1967UpgradeUpgradeable
    uint256[50] __gap7;

    // UUPSUpgradeable
    uint256[50] __gap8;

    // PausableUpgradeable
    bool _paused;
    uint256[49] __gap9;

    // ERC20Upgradeable
    string _name;
    string _symbol;

    // Stablecoin
    MintOperationArrays.Array _mintOperations;
    MintPoolArrays.Array _mintPools;
    ProofOfReserve.Params _proofOfReserveParams;
    Redemption.Params _redemptionParams;

    /* Additionally, we have several keccak-based storage locations.
     * If you add more keccak-based storage mappings, such as mappings, you must document them here.
     * If the length of the keccak input is the same as an existing mapping, it is possible there could be a
     * preimage collision.
     * A preimage collision can be used to attack the contract by treating one storage location as another,
     * which would always be a critical issue.
     * Carefully examine future keccak-based storage to ensure there can be no preimage collisions.
     *******************************************************************************************************
     ** length     input                                                         usage
     *******************************************************************************************************
     * Fill Me
     **/
}

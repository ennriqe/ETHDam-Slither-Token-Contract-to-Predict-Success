// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AggregatorV3Interface} from "chainlink-v2.7.2/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable-v4.9.5/contracts/token/ERC20/IERC20Upgradeable.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable-v4.9.5/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {AccessControlEnumerableUpgradeable} from "./abstract/1GBP_AccessControlEnumerableUpgradeable.sol";
import {UUPSUpgradeable} from "./abstract/1GBP_UUPSUpgradeable.sol";
import {PausableUpgradeable} from "./abstract/1GBP_PausableUpgradeable.sol";
import {ERC20Upgradeable} from "./abstract/1GBP_ERC20Upgradeable.sol";

import {Count} from "./library/ApprovalSet.sol";
import {MintOperations} from "./library/MintOperation.sol";
import {MintOperationArrays, OpIndices, OpIndex} from "./library/MintOperationArray.sol";
import {MintPools} from "./library/MintPool.sol";
import {MintPoolArrays, PoolIndices, PoolIndex} from "./library/MintPoolArray.sol";
import {ProofOfReserve} from "./library/ProofOfReserve.sol";
import {Redemption} from "./library/Redemption.sol";

contract Stablecoin is AccessControlEnumerableUpgradeable, UUPSUpgradeable, PausableUpgradeable, ERC20Upgradeable {
    using MintOperations for MintOperations.Op;
    using MintOperationArrays for MintOperationArrays.Array;
    using OpIndices for OpIndex;
    using MintPools for MintPools.Pool;
    using MintPoolArrays for MintPoolArrays.Array;
    using PoolIndices for PoolIndex;
    using ProofOfReserve for ProofOfReserve.Params;
    using Redemption for Redemption.Params;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MINT_RATIFIER_ROLE = keccak256("MINT_RATIFIER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant FROZEN_ROLE = keccak256("FROZEN_ROLE");
    bytes32 public constant REDEMPTION_ADMIN_ROLE = keccak256("REDEMPTION_ADMIN_ROLE");
    bytes32 public constant REDEMPTION_ADDRESS_ROLE = keccak256("REDEMPTION_ADDRESS_ROLE");

    uint256 public constant CENT = 10 ** 16;
    address public constant MAX_REDEMPTION_ADDRESS = address(0x100000);

    event PushMintPool(PoolIndex poolIndex, Count signatures, uint256 threshold, uint256 limit);
    event PopMintPool(PoolIndex poolIndex);

    event SetMintSignatures(PoolIndex poolIndex, Count signatures);
    event SetMintThreshold(PoolIndex poolIndex, uint256 threshold);
    event SetMintLimit(PoolIndex poolIndex, uint256 limit);

    event EnableProofOfReserve();
    event DisableProofOfReserve();
    event SetProofOfReserveFeed(AggregatorV3Interface feed);
    event SetProofOfReserveHeartbeat(uint256 heartbeat);

    event SetRedemptionMin(uint256 min);

    event ApproveRefillMintPool(PoolIndex poolIndex, address approver);
    event FinalizeRefillMintPool(PoolIndex poolIndex);

    event RequestMint(OpIndex opIndex, address to, uint256 value, address requester);
    event RatifyMint(OpIndex opIndex, address ratifier);
    event FinalizeMint(OpIndex opIndex, PoolIndex poolIndex);
    event RevokeMint(OpIndex opIndex, address revoker);

    event Redeem(address redemptionAddress, uint256 amount);

    event Burn(address from, uint256 amount);
    event ReclaimEther(address admin, uint256 amount);
    event ReclaimToken(IERC20Upgradeable token, address admin, uint256 amount);

    error AccountHasFrozenRole(address account);
    error MintToAddressZeroOrRedemptionAddress(address to);
    error AmountDoesNotHaveExactCent(uint256 amount);

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name_, string memory symbol_) public initializer {
        _initialize(name_, symbol_);
    }

    function _initialize(string memory name_, string memory symbol_) private {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        ERC20Upgradeable.__ERC20_init(name_, symbol_);
        UUPSUpgradeable.__UUPSUpgradeable_init();
        PausableUpgradeable.__Pausable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(REDEMPTION_ADDRESS_ROLE, REDEMPTION_ADMIN_ROLE);
        _proofOfReserveParams.setDecimals(decimals());
        assert(CENT == 10 ** (decimals() - 2));
    }

    function initializeV2() public reinitializer(2) {
        string memory name_ = "poundtoken";
        string memory symbol_ = "1GBP";

        // poundtoken Multisig
        address admin = address(0xc19b8A572fC96ded6215B682094Db767f20465aa);

        address[] memory minterList = new address[](1);
        // Archblock's 1GBP_MINT_KEY:
        minterList[0] = address(0x14d70a8bBc68d3c9E718F09B08a32EbA4FBFEa65);

        address[] memory mintRatifierList = new address[](3);
        // poundtoken ratifiers
        mintRatifierList[0] = address(0xBe8e1b571900af2CB132144801cE9dfa8bd18843);
        mintRatifierList[1] = address(0x4D5943626127a2A0361Fc76E16e618cD70a9C05b);
        mintRatifierList[2] = address(0xB2e72551BB75F1EB49B79006b6BF1461a93E6525);

        address[] memory pauserList = new address[](4);
        // poundtoken ratifiers can also pause
        pauserList[0] = address(0xBe8e1b571900af2CB132144801cE9dfa8bd18843);
        pauserList[1] = address(0x4D5943626127a2A0361Fc76E16e618cD70a9C05b);
        pauserList[2] = address(0xB2e72551BB75F1EB49B79006b6BF1461a93E6525);
        // Archblock's multisig
        pauserList[3] = address(0x16cEa306506c387713C70b9C1205fd5aC997E78E);

        address[] memory redemptionAdminList = new address[](1);
        // Archblock's 1GBP_REGISTRY_KEY
        redemptionAdminList[0] = address(0x04144e86D3D51CAd813e8f5EF62cF760Bd810EeB);

        // Previously blacklisted addresses not on the OFAC list
        address[] memory blacklist = new address[](6);
        blacklist[0] = address(0xfEC8A60023265364D066a1212fDE3930F6Ae8da7);
        blacklist[1] = address(0x6aCDFBA02D390b97Ac2b2d42A63E85293BCc160e);
        blacklist[2] = address(0xeA6b5Be96f49c876250A3A8Ccbe9AED36627626e);
        blacklist[3] = address(0x905b63Fff465B9fFBF41DeA908CEb12478ec7601);
        blacklist[4] = address(0x38735f03b30FbC022DdD06ABED01F0Ca823C6a94);
        blacklist[5] = address(0xFAC583C0cF07Ea434052c49115a4682172aB6b4F);

        _initializeV2WithParams(
            name_,
            symbol_,
            admin,
            minterList,
            mintRatifierList,
            pauserList,
            redemptionAdminList,
            blacklist
        );
    }

    function _initializeV2WithParams(
        string memory name_,
        string memory symbol_,
        address admin,
        address[] memory minterList,
        address[] memory ratifierList,
        address[] memory pauserList,
        address[] memory redemptionAdminList,
        address[] memory frozenList
    ) private {
        _initialize(name_, symbol_);

        uint256 onePound = 10 ** decimals();

        // Single multisig mint pool
        pushMintPool(Count.wrap(2), (10_000_000 * onePound), (10_000_000 * onePound));

        _redemptionParams.setMin(10 * onePound);

        grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRoles(MINTER_ROLE, minterList);
        _grantRoles(MINT_RATIFIER_ROLE, ratifierList);
        _grantRoles(PAUSER_ROLE, pauserList);
        _grantRoles(REDEMPTION_ADMIN_ROLE, redemptionAdminList);

        uint256 frozenLength = frozenList.length;
        for (uint256 i; i < frozenLength; i++) {
            require(__DEPRECATED_blacklisted[frozenList[i]]);
            grantRole(FROZEN_ROLE, (frozenList[i]));
        }
    }

    function _grantRoles(bytes32 role, address[] memory addresses) private onlyInitializing {
        uint256 addressesLength = addresses.length;
        for (uint256 i; i < addressesLength; i++) {
            grantRole(role, (addresses[i]));
        }
    }

    /*
     * CAUTION: If you are able to call this function directly outside of testing,
     * then something must have gone wrong with the upgrade.
     * To avoid a frontrun contract takeover, you MUST use `upgradeToAndCall()` with `initializeV2()` above.
     *
     * DO NOT USE `upgradeTo()`.
     */
    function initializeV2WithParams(
        string memory name_,
        string memory symbol_,
        address admin,
        address[] memory minterList,
        address[] memory ratifierList,
        address[] memory pauserList,
        address[] memory redemptionAdminList,
        address[] memory frozenList
    ) public reinitializer(2) {
        _initializeV2WithParams(
            name_,
            symbol_,
            admin,
            minterList,
            ratifierList,
            pauserList,
            redemptionAdminList,
            frozenList
        );
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal view virtual override {
        if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            return;
        }
        _requireNotPaused();
        if (hasRole(FROZEN_ROLE, from)) {
            revert AccountHasFrozenRole(from);
        }
        if (hasRole(FROZEN_ROLE, to)) {
            revert AccountHasFrozenRole(to);
        }
    }

    function _afterTokenTransfer(address, address to, uint256 amount) internal virtual override {
        if (to != address(0) && uint160(to) <= uint160(MAX_REDEMPTION_ADDRESS)) {
            _checkRole(REDEMPTION_ADDRESS_ROLE, to);
            if (amount % CENT != 0) {
                revert AmountDoesNotHaveExactCent(amount);
            }
            _redemptionParams.checkRedemption(amount);

            _burn(to, amount);
            emit Redeem(to, amount);
        }
    }

    function _isMintRatifier(address address_) private view returns (bool) {
        return hasRole(MINT_RATIFIER_ROLE, address_);
    }

    function _isUnfiltered(address) private pure returns (bool) {
        return true;
    }

    function viewMintPoolsCount() external view returns (PoolIndex) {
        return _mintPools.length();
    }

    function viewMintPool(PoolIndex poolIndex) external view returns (Count, uint256, uint256, uint256, Count, Count) {
        MintPools.Pool storage pool = _mintPools.at(poolIndex);
        return (
            pool.signatures(),
            pool.threshold(),
            pool.limit(),
            pool.value(),
            pool.refillApprovalsCount(_isMintRatifier),
            pool.refillApprovalsCount(_isUnfiltered)
        );
    }

    function viewUnfilteredMintPoolRefillApproval(
        PoolIndex poolIndex,
        Count refillApprovalIndex
    ) external view returns (address) {
        return _mintPools.at(poolIndex).refillApprovalAtIndex(refillApprovalIndex);
    }

    function viewMintOperationsCount() external view returns (OpIndex) {
        return _mintOperations.length();
    }

    function viewMintOperation(
        OpIndex opIndex
    ) external view returns (MintOperations.Status, address, uint256, Count, Count) {
        MintOperations.Op storage operation = _mintOperations.at(opIndex);
        return (
            operation.status(),
            operation.to(),
            operation.value(),
            operation.ratifierApprovals(_isMintRatifier),
            operation.ratifierApprovals(_isUnfiltered)
        );
    }

    function viewUnfilteredMintOperationRatifierApproval(
        OpIndex opIndex,
        Count ratifierApprovalIndex
    ) external view returns (address) {
        return _mintOperations.at(opIndex).ratifierApprovalAtIndex(ratifierApprovalIndex);
    }

    function viewProofOfReserve() external view returns (bool, uint8, AggregatorV3Interface, uint256) {
        return (
            _proofOfReserveParams.enabled(),
            _proofOfReserveParams.decimals(),
            _proofOfReserveParams.feed(),
            _proofOfReserveParams.heartbeat()
        );
    }

    function viewMinimumRedemptionAmount() external view returns (uint256) {
        return _redemptionParams.min();
    }

    function pushMintPool(Count signatures, uint256 threshold, uint256 limit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        PoolIndex poolIndex = _mintPools.length();
        _mintPools.push();
        _mintPools.setSignatures(poolIndex, signatures);
        _mintPools.setThreshold(poolIndex, threshold);
        _mintPools.setLimit(poolIndex, limit);
        refillLastMintPoolFromAdmin();
        emit PushMintPool(poolIndex, signatures, threshold, limit);
    }

    function popMintPool() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintPools.pop();
        emit PopMintPool(_mintPools.length());
    }

    function setMintSignatures(PoolIndex poolIndex, Count signatures) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintPools.setSignatures(poolIndex, signatures);
        emit SetMintSignatures(poolIndex, signatures);
    }

    function setMintThreshold(PoolIndex poolIndex, uint256 threshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintPools.setThreshold(poolIndex, threshold);
        emit SetMintThreshold(poolIndex, threshold);
    }

    function setMintLimit(PoolIndex poolIndex, uint256 limit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintPools.setLimit(poolIndex, limit);
        emit SetMintLimit(poolIndex, limit);
    }

    function enableProofOfReserve() external onlyRole(PAUSER_ROLE) {
        _proofOfReserveParams.setEnabled(true);
        emit EnableProofOfReserve();
    }

    function disableProofOfReserve() external onlyRole(PAUSER_ROLE) {
        _proofOfReserveParams.setEnabled(false);
        emit DisableProofOfReserve();
    }

    function setProofOfReserveFeed(AggregatorV3Interface feed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _proofOfReserveParams.setFeed(feed);
        emit SetProofOfReserveFeed(feed);
    }

    function setProofOfReserveHeartbeat(uint256 heartbeat) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _proofOfReserveParams.setHeartbeat(heartbeat);
        emit SetProofOfReserveHeartbeat(heartbeat);
    }

    function setRedemptionMin(uint256 min) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _redemptionParams.setMin(min);
        emit SetRedemptionMin(min);
    }

    function approveRefillMintPoolFromNextPool(PoolIndex poolIndex) public onlyRole(MINT_RATIFIER_ROLE) {
        _mintPools.at(poolIndex).approveRefillFromPool(msg.sender);
        emit ApproveRefillMintPool(poolIndex, msg.sender);
    }

    function finalizeRefillMintPoolFromNextPool(PoolIndex poolIndex) public {
        _mintPools.at(poolIndex).finalizeRefillFromPool(_mintPools.at(poolIndex.next()), _isMintRatifier);
        emit FinalizeRefillMintPool(poolIndex);
    }

    function approveThenFinalizeRefillMintPoolFromNextPool(PoolIndex poolIndex) external {
        approveRefillMintPoolFromNextPool(poolIndex);
        finalizeRefillMintPoolFromNextPool(poolIndex);
    }

    function refillLastMintPoolFromAdmin() public onlyRole(DEFAULT_ADMIN_ROLE) {
        PoolIndex lastPoolIndex = _mintPools.length().prev();
        _mintPools.at(lastPoolIndex).refillFromAdmin();
        emit ApproveRefillMintPool(lastPoolIndex, msg.sender);
        emit FinalizeRefillMintPool(lastPoolIndex);
    }

    function requestMint(address to, uint256 value) public onlyRole(MINTER_ROLE) {
        if (uint160(to) <= uint160(MAX_REDEMPTION_ADDRESS)) {
            revert MintToAddressZeroOrRedemptionAddress(to);
        }
        if (value % CENT != 0) {
            revert AmountDoesNotHaveExactCent(value);
        }
        OpIndex opIndex = _mintOperations.length();
        _mintOperations.push().request(to, value);
        emit RequestMint(opIndex, to, value, msg.sender);
    }

    function ratifyMint(OpIndex opIndex) public onlyRole(MINT_RATIFIER_ROLE) {
        _mintOperations.at(opIndex).approve(msg.sender);
        emit RatifyMint(opIndex, msg.sender);
    }

    function finalizeMint(OpIndex opIndex, PoolIndex poolIndex) public {
        MintOperations.Op storage op = _mintOperations.at(opIndex);
        MintPools.Pool storage pool = _mintPools.at(poolIndex);
        uint256 value = op.value();

        _proofOfReserveParams.checkMint(value, totalSupply());

        op.finalize(pool.signatures(), _isMintRatifier);
        pool.spend(value);
        _mint(op.to(), value);
        emit FinalizeMint(opIndex, poolIndex);
    }

    function requestThenFinalizeMint(address to, uint256 value, PoolIndex poolIndex) external {
        OpIndex opIndex = _mintOperations.length();
        requestMint(to, value);
        finalizeMint(opIndex, poolIndex);
    }

    function ratifyThenFinalizeMint(OpIndex opIndex, PoolIndex poolIndex) external {
        ratifyMint(opIndex);
        finalizeMint(opIndex, poolIndex);
    }

    function revokeMint(OpIndex opIndex) external onlyRole(MINTER_ROLE) {
        _mintOperations.at(opIndex).revoke();
        emit RevokeMint(opIndex, msg.sender);
    }

    function burn(address account, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (amount % CENT != 0) {
            revert AmountDoesNotHaveExactCent(amount);
        }
        _burn(account, amount);
        emit Burn(account, amount);
    }

    function reclaimEther() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit ReclaimEther(msg.sender, balance);
    }

    function reclaimToken(IERC20Upgradeable token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = token.balanceOf(address(this));
        SafeERC20Upgradeable.safeTransfer(token, msg.sender, balance);
        emit ReclaimToken(token, msg.sender, balance);
    }
}

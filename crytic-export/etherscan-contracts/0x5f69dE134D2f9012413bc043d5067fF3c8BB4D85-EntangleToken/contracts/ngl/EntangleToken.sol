// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@entangle_protocol/oracle-sdk/contracts/IProposer.sol";

error EntangleToken__E1(); //aggregationSpotter is already set : EntangleToken
error EntangleToken__E2(); //bridgeRouterAddress is already set : EntangleToken
error EntangleToken__E3(); //Arguments lentgh missmatch
error EntangleToken__E4(); //Increase/decrease allowance is deprecated
error EntangleToken__E5(); //Bridge is not active yet, aggregationSpotter not set : EntangleToken
error EntangleToken__E6(); //Bridge is not active yet, bridgeRouterAddress not set : EntangleToken
error EntangleToken__E7(); //Cannot bridge to the same chain
error EntangleToken__E8(); //Amount is less than min amount
error EntangleToken__E9(); //The bridge and extract is available only for EOB

/// @title EntangleToken
/// @notice Represents an *NGL token used for bridging operations between different chains.
contract EntangleToken is Initializable, ERC20Upgradeable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant SPOTTER = keccak256("SPOTTER");
    bytes32 public constant LAZY = keccak256("LAZY");
    bytes32 public constant BURNER = keccak256("BURNER");
    
    IProposer aggregationSpotter;
    address lazySpotter;
    bytes bridgeRouterAddress;
    bytes32 protocolId;
    uint256 eobChainId;
    address feeCollector;
    mapping(uint256 destChainId => uint256 minAmount) minBridgeAmounts;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        bytes32 _protocolId,
        uint256 _eobChainId,
        address _admin,
        address _startReceipient,
        uint256 _startAmount
    )
        initializer public
    {
        __ERC20_init(name,symbol);
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(BURNER, ADMIN);
        _grantRole(ADMIN, _admin);
        protocolId = _protocolId;
        eobChainId = _eobChainId;
        _mint(_startReceipient, _startAmount);
    }

    /// @notice Grants the LAZY role.
    /// @param _lazySpotter The address of the lazy spotter.
    function setLazySpotter(address _lazySpotter) external onlyRole(ADMIN) {
        if (lazySpotter != address(0)) revert EntangleToken__E1();
        lazySpotter = _lazySpotter;
        _grantRole(LAZY, _lazySpotter);
    }

    /// @notice Sets the aggregation spotter address.
    /// This value can only be set ONCE.
    /// @param _as The address of the aggregation spotter.
    function setAggregationSpotter(address _as) external onlyRole(ADMIN) {
        if (address(aggregationSpotter) != address(0)) revert EntangleToken__E1();
        aggregationSpotter = IProposer(_as);
        _grantRole(SPOTTER, _as);
    }

    /// @notice Sets the bridge router address.
    /// This value can only be set ONCE.
    /// @param _bridgeRouterAddress The address of the bridge router.
    function setBridgeRouterAddress(address _bridgeRouterAddress) external onlyRole(ADMIN) {
        if (bridgeRouterAddress.length != 0) revert EntangleToken__E2();
        bridgeRouterAddress = abi.encode(_bridgeRouterAddress);
    }

    /// @notice Sets the fee collector address.
    /// @param _feeCollector The address of the fee collector.
    function setFeeCollector(address _feeCollector) external onlyRole(ADMIN) {
        feeCollector = _feeCollector;
    }

    /// @notice Sets the minimum amount of tokens that can be bridged.
    /// @param chainIds The IDs of the chains.
    /// @param minAmounts The minimum amounts of tokens that can be bridged to chains
    function setMinBridgeAmount(uint256[] memory chainIds, uint256[] memory minAmounts) public onlyRole(ADMIN) {
        if (chainIds.length != minAmounts.length) revert EntangleToken__E3();
        uint256 chainIdsLen = chainIds.length;
        for (uint256 i; i < chainIdsLen; ++i) {
            uint256 key = chainIds[i];
            uint256 value = minAmounts[i];
            minBridgeAmounts[key] = value;
        }
    }

    /// @notice Pauses token bridging.
    function pauseBridge() external onlyRole(ADMIN) {
        _pause();
    }

    /// @notice Unpauses token bridging.
    function unpauseBridge() external onlyRole(ADMIN) {
        _unpause();
    }

    /// @notice Deprecated function: Reverts as increaseAllowance is deprecated.
    function increaseAllowance() public pure {
        revert EntangleToken__E4();
    }

    /// @notice Deprecated function: Reverts as decreaseAllowance is deprecated.
    function decreaseAllowance() public pure {
        revert EntangleToken__E4();
    }

    /// @notice Event emitted upon successful token bridging.
    event BridgeDone(address to, uint256 amount, bytes32 txhash, uint256 fromChain, bytes32 marker);

    /// @notice LazySpotter mint function for message with tokens
    /// @param _to The recipient address
    /// @param _amount The amount of tokens to mint
    function lazyMint(address _to, uint256 _amount) external onlyRole(LAZY) whenNotPaused {
        _mint(_to, _amount);
    }

    /// @notice LazySpotter burn function for message with tokens
    /// @param _amount The amount of tokens to mint
    function lazyBurn(uint256 _amount) external onlyRole(LAZY) whenNotPaused {
        _burn(_msgSender(), _amount);
    }

    /// @notice Redeems tokens on the receiving chain after a successful bridge operation.
    /// @param b Keeper encoded data, real params below
    /// @custom:param _to The recipient address in bytes
    /// @custom:param _amount The amount of tokens to transfer.
    /// @custom:param _fee The fee deducted from the transferred amount.
    /// @custom:param _txhash The transaction hash from the sending chain.
    /// @custom:param _fromChain The ID of the sending chain.
    function redeem(bytes calldata b) external onlyRole(SPOTTER) whenNotPaused {
        (, , , , bytes memory params) = abi.decode(b, (bytes32, uint256, uint256, bytes32, bytes));
        (bytes memory _to, uint256 _amount, uint256 _fee, bytes32 _txhash, uint256 _fromChain, bytes32 _marker) = abi.decode(
            params,
            (bytes, uint256, uint256, bytes32, uint256, bytes32)
        );
        address to = abi.decode(_to, (address));
        _mint(to, _amount - _fee);
        _mint(feeCollector, _fee);
        emit BridgeDone(to, _amount, _txhash, _fromChain, _marker);
    }

    /// @notice Initiates the token bridging operation between chains.
    /// @param _chainIdTo The ID of the target chain for token bridging.
    /// @param _to The address of the recipient on the target chain.
    /// @param _amount The amount of tokens to bridge.
    /// @param _marker The marker for the currect bridge operation.
    function bridge(uint256 _chainIdTo, bytes memory _to, uint256 _amount, bool unwrap, bytes32 _marker) external whenNotPaused {
        if (address(aggregationSpotter) == address(0)) revert EntangleToken__E5();
        if (bridgeRouterAddress.length == 0) revert EntangleToken__E6();
        if (_chainIdTo == block.chainid) revert EntangleToken__E7();
        if (_amount < minBridgeAmounts[_chainIdTo]) revert EntangleToken__E8();
        if (unwrap && _chainIdTo != eobChainId) revert EntangleToken__E9();

        _burn(msg.sender, _amount);
        aggregationSpotter.propose(
            protocolId,
            eobChainId,
            bridgeRouterAddress,
            abi.encode(bytes4(keccak256("bridge(bytes)"))),
            abi.encode(abi.encode(msg.sender), _chainIdTo, _to, _amount, unwrap, _marker)
        );
    }

    /// @notice Burns a specified amount of tokens.
    /// Only the burner role can execute this function.
    /// @param _amount The amount of wrapped tokens to burn.
    function burn(uint256 _amount) external onlyRole(BURNER) {
        _burn(msg.sender, _amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(ADMIN)
        override
    {}
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity >=0.8.0;

import {EndaomentAuth} from "./lib/auth/EndaomentAuth.sol";
import {Registry} from "./Registry.sol";
import {Entity} from "./Entity.sol";
import {Portfolio} from "./Portfolio.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";

/**
 * @notice An Endaoment ecosystem contract capabale of transfering base tokens to Endaoment entities, updating their balances without triggering fees or emitting misleading events.
 * @dev This is due to this contract being enabled as a valid entity on the `Registry` and capable of calling `receiveTransfer` on entities.
 */
contract EntityBaseTokenTransferor is EndaomentAuth {
    using SafeTransferLib for ERC20;

    /// STRUCTS
    struct EntityTransfer {
        Entity entity;
        uint256 amount;
    }

    /// STATE
    /// @notice The Endaoment registry contract
    Registry public immutable registry;

    /// ERRORS
    /// @notice Error when the transfer destination isn't a valid and enabled Endaoment entity.
    error InvalidEntity();
    /// @notice Error when the transfer source isn't a valid and enabled Endaoment portfolio.
    error InvalidPortfolio();
    /// @notice Error when a call to another contract fails.
    error CallFailed(bytes response);

    /// EVENTS
    /// @notice Emitted when a transfer is made to an Endaoment entity.
    event TransferredToEntity(address indexed from, Entity indexed entity, uint256 amount);

    /**
     * @param _registry The Endaoment registry contract
     */
    constructor(Registry _registry) {
        __initEndaomentAuth(_registry, "");
        registry = _registry;
    }

    /**
     * Modifier to only allow valid and active Endaoment entities as transfer destinations.
     * @param _entity The attempted entity
     */
    modifier isActiveEntity(Entity _entity) {
        _checkEntity(_entity);
        _;
    }

    /**
     * Modifier to only allow valid and active Endaoment portfolios as callers.
     */
    modifier isActivePortfolioCaller() {
        if (!registry.isActivePortfolio(Portfolio(msg.sender))) revert InvalidPortfolio();
        _;
    }

    /**
     * Check if an entity is valid and active
     * @param _entity The entity to check
     */
    function _checkEntity(Entity _entity) private view {
        if (!registry.isActiveEntity(_entity)) revert InvalidEntity();
    }

    /**
     * Transfer base token from caller and consolidate balance of the Endaoment entity.
     * @param _entity The entity to transfer to.
     * @param _amount The amount to transfer.
     * @notice This functions exists so Endaoment admins can transfer arbitrary amounts of base tokens to entities without triggering fees.
     * @dev Caller must pre `approve` this contract to transfer the desired amount.
     */
    function transferFromCaller(Entity _entity, uint256 _amount) external requiresAuth isActiveEntity(_entity) {
        _transferToEntity(msg.sender, _entity, _amount);
    }

    /**
     * Batch transfer base token from caller and consolidate balance of the receiving Endaoment entities.
     * @param _entityTransfers The entity transfers to make.
     * @notice This functions exists so Endaoment admins can transfer arbitrary amounts of base tokens to entities without triggering fees.
     * @dev Caller must pre `approve` this contract to transfer the desired amount.
     */
    function batchTransferFromCaller(EntityTransfer[] calldata _entityTransfers) external requiresAuth {
        for (uint256 i = 0; i < _entityTransfers.length; ++i) {
            EntityTransfer memory _transfer = _entityTransfers[i];
            _checkEntity(_transfer.entity);
            _transferToEntity(msg.sender, _transfer.entity, _transfer.amount);
        }
    }

    /**
     * Transfer base token from an Endaoment portfolio to an Endaoment entity.
     * @param _entity The entity to transfer to.
     * @param _amount The amount to transfer.
     * @notice This functions exists so Endaoment portfolios can transfer arbitrary amounts of base tokens to entities without triggering fees.
     * An example of this use case is for T+N portfolios and their async nature of transferring base tokens back to entities on sale consolidation.
     * @dev This function is only callable by active Endaoment portfolios.
     * @dev Portfolio caller must pre `approve` this contract to transfer the desired amount.
     */
    function transferFromPortfolio(Entity _entity, uint256 _amount)
        external
        isActivePortfolioCaller
        isActiveEntity(_entity)
    {
        _transferToEntity(msg.sender, _entity, _amount);
    }

    /**
     * Batch transfer base token from an Endaoment portfolio to Endaoment entities.
     * @param _entityTransfers The entity transfers to make.
     * @notice This functions exists so Endaoment portfolios can transfer arbitrary amounts of base tokens to entities without triggering fees.
     * @dev This function is only callable by active Endaoment portfolios.
     * @dev Portfolio caller must pre `approve` this contract to transfer the desired amount.
     */
    function batchTransferFromPortfolio(EntityTransfer[] calldata _entityTransfers) external isActivePortfolioCaller {
        for (uint256 i = 0; i < _entityTransfers.length; ++i) {
            EntityTransfer memory _transfer = _entityTransfers[i];
            _checkEntity(_transfer.entity);
            _transferToEntity(msg.sender, _transfer.entity, _transfer.amount);
        }
    }

    /**
     * Transfer base token to an Endaoment entity.
     * @param _from The address to transfer from.
     * @param _entity The entity to transfer to.
     * @param _amount The amount to transfer.
     */
    function _transferToEntity(address _from, Entity _entity, uint256 _amount) private {
        // Emit event
        emit TransferredToEntity(_from, _entity, _amount);

        // Update entity balance through receiving
        _entity.receiveTransfer(_amount);

        // Transfer to entity, transferring from approved balance from the caller
        registry.baseToken().safeTransferFrom(_from, address(_entity), _amount);
    }

    /**
     * Make arbitrary calls to other contracts as this contract.
     * @param _target The target contract.
     * @param _value The ETH value to send.
     * @param _data The calldata.
     * @return _response The response from the call.
     * @notice This function exists so Endaoment admins can make arbitrary calls to other contracts as this contract, specially if to unlock incorrectly sent assets.
     */
    function callAsContract(address _target, uint256 _value, bytes memory _data)
        external
        payable
        requiresAuth
        returns (bytes memory)
    {
        (bool _success, bytes memory _response) = payable(_target).call{value: _value}(_data);
        if (!_success) revert CallFailed(_response);
        return _response;
    }
}

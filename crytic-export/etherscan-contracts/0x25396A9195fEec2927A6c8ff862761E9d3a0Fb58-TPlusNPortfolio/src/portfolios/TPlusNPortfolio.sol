//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import {EntityBaseTokenTransferor} from "../EntityBaseTokenTransferor.sol";
import {TPlusNAsset} from "./TPlusNAsset.sol";
import {Registry} from "../Registry.sol";
import {Entity} from "../Entity.sol";
import {Portfolio} from "../Portfolio.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Math} from "../lib/Math.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

/// ENUMS
enum ConsolidationOperation {
    Deposit,
    Redeem
}

/// STRUCTS
/**
 * @notice Arguments for constructor. Using a struct to avoid stack too deep error.
 * @param _registry Endaoment registry.
 * @param _receiptAsset Address of the receipt asset. Should normally be a `TPlusNAsset` contract.
 * @param _shareTokenName Name of ERC20 portfolio share token.
 * @param _shareTokenSymbol Symbol of ERC20 portfolio share token.
 * @param _ebtt Address of the EBTT contract.
 * @param _processor Address to automatically route deposit base token to.
 * @param _minDeposit Minimum base token amount allowed for a valid deposit.
 * @param _cap Maximum amount of assets this portfolio can hold.
 * @param _feeTreasury Address of treasury that should receive fees.
 * @param _depositFee Percentage fee as ZOC that should go to treasury on deposit. (100 = 1%).
 * @param _redemptionFee Percentage fee as ZOC that should go to treasury on redemption. (100 = 1%).
 * @param _aumRate Percentage fee per second (as WAD) that should accrue to treasury as AUM fee. (1e16 = 1%).
 */
struct ConstructorArgs {
    Registry registry;
    address receiptAsset;
    string shareTokenName;
    string shareTokenSymbol;
    EntityBaseTokenTransferor ebtt;
    address processor;
    uint256 minDeposit;
    uint256 cap;
    address feeTreasury;
    uint256 depositFee;
    uint256 redemptionFee;
    uint256 aumRate;
}

/**
 * @notice Struct representing a single consolidation for a deposit/purchase or redeem/sale operation.
 * @param operation The type of consolidation operation - deposit/purchase or redeem/sale.
 * @param entity The entity whose pending balance should be consolidated.
 * @param amountBaseToken The amount of base token to consolidate. For purchases, this is the amount of base token used. For sales, this is the amount of base token received.
 * @param amountAssets The amount of assets to consolidate. For purchases, this is the amount of assets purchased. For sales, this is the amount of assets sold.
 */
struct Consolidation {
    ConsolidationOperation operation;
    Entity entity;
    uint256 amountBaseToken;
    uint256 amountAssets;
}

contract TPlusNPortfolio is Portfolio {
    using SafeTransferLib for ERC20;
    using Math for uint256;

    /// STATE

    /// @notice The EBTT contract.
    EntityBaseTokenTransferor public immutable ebtt;
    /// @notice The address to automatically route base tokens from and to on deposits and sales.
    address public processor;
    /// @notice Minimum base token amount that can be deposited.
    uint256 public minDeposit;
    /// @notice Maintenance flag to pause functionality.
    bool public underMaintenance;
    /// @notice Pending purchase balance of base tokens per address.
    mapping(Entity => uint256) public pendingPurchaseBalance;
    /// @notice Pending sale assets per address.
    mapping(Entity => uint256) public pendingSaleAssets;

    /// ERRORS

    /// @notice Emitted when deposit is below minimum.
    error MinDeposit();
    /// @notice Emitted when called under maintenance.
    error UnderMaintenance();
    /// @notice Emitted when informed entity parameter is bad (e.g. missing information, duplicated entities).
    error BadEntityInput();
    /// @notice Emitted when insufficient balances on consolidation.
    error InsufficientBalance();

    /// EVENTS

    /// @notice Emitted when processor is set.
    event ProcessorSet(address newProcessor);
    /// @notice Emitted when minDeposit is set.
    event MinDepositSet(uint256 newMinDeposit);
    /// @notice Emitted when underMaintenance is set.
    event UnderMaintenanceSet(bool newUnderMaintenance);
    /// @notice Emitted when a deposit/purchase consolidation is made.
    event DepositConsolidated(
        Entity indexed entity, uint256 amountBaseToken, uint256 amountAssets, uint256 amountShares
    );
    /// @notice Emitted when a correction mint is made.
    event CorrectionShareMinted(Entity indexed entity, uint256 amountShares);
    /// @notice Emitted when a correction burn is made.
    event CorrectionShareBurned(Entity indexed entity, uint256 amountShares);
    /// @notice Emitted when a redemption/sale consolidation is made.
    event RedeemConsolidated(Entity indexed entity, uint256 amountBaseToken, uint256 amountAssets, uint256 fee);

    /**
     * @param _args Constructor arguments struct.
     * @dev Args are passed in a struct to avoid stack too deep errors.
     * @dev The `true` parameter is to set this portfolio as `async` in the parent `Portfolio` contract. Async portfolios handle share lifecycle differently.
     * @dev EBTT is required to properly process payments back to entites on sale consolidations.
     * @dev While `cap` is not enforced in contract, its value can be utilized by UI to implement the behavior.
     */
    constructor(ConstructorArgs memory _args)
        Portfolio(
            _args.registry,
            _args.receiptAsset,
            _args.shareTokenName,
            _args.shareTokenSymbol,
            true, // Async portfolio, hence setting `_async` to true
            _args.cap,
            _args.feeTreasury,
            _args.depositFee,
            _args.redemptionFee,
            _args.aumRate
        )
    {
        // Approve EBTT to transfer this portfolio's balance for sale consolidations
        ebtt = _args.ebtt;
        baseToken.safeApprove(address(ebtt), type(uint256).max);

        processor = _args.processor;
        emit ProcessorSet(processor);

        minDeposit = _args.minDeposit;
        emit MinDepositSet(minDeposit);
    }

    /**
     * @inheritdoc Portfolio
     */
    function _getAsset(address _receiptAsset) internal pure override returns (address) {
        return _receiptAsset;
    }

    /**
     * @inheritdoc Portfolio
     */
    function convertReceiptAssetsToAssets(uint256 _receiptAssets) public pure override returns (uint256) {
        return _receiptAssets;
    }

    /**
     * @inheritdoc Portfolio
     * @notice T+N portfolios do not enforce cap onchain.
     * @dev Cap is not enforced because async portfolios do not have direct access to the spot price of the asset, hence not being able to determine a cap syncronously to deposits.
     * @dev While `cap` is not enforced in contract, it is settable in the constructor so external logic can read and utilize it.
     */
    function _checkCap() internal pure override {}

    /**
     * @inheritdoc Portfolio
     * @dev As an `async` portfolio, T+N portfolio do not mint shares on `deposit`, rather handling it on consolidations.
     * @dev Deposits smaller than `minDeposit` revert.
     */
    function _deposit(uint256 _amountBaseToken, bytes calldata /* _data */ )
        internal
        override
        returns (uint256, /* shares */ uint256, /* assets */ uint256 /* fee */ )
    {
        // Check if deposit is above minimum
        if (_amountBaseToken < minDeposit) revert MinDeposit();
        // Check if under maintenance
        if (underMaintenance) revert UnderMaintenance();

        // Calculate fee and net amount to be deposited and used for purchase
        // TODO: move deposit fee logic to `Portfolio`, for all portfolios
        (uint256 _amountIn, uint256 _amountFee) = _calculateFee(_amountBaseToken, depositFee);

        // Transfer amount from entity to `processor`
        baseToken.safeTransferFrom(msg.sender, processor, _amountIn);

        // Transfer fee to treasury
        baseToken.safeTransferFrom(msg.sender, feeTreasury, _amountFee);

        // Update pending balance
        unchecked {
            // Unchecked: no realistic amount of base token will overflow
            pendingPurchaseBalance[Entity(payable(msg.sender))] += _amountIn;
        }

        // No acquired shares or assets, and base token fee amount
        return (0, 0, _amountFee);
    }

    /**
     * @inheritdoc Portfolio
     * @notice Returns (0, 0) to signal that no asset and base token are produced on reddem for T+N.
     */
    function _redeem(uint256 _amountShares, bytes calldata /* _data */ )
        internal
        override
        returns (uint256, /* assetsOut */ uint256 /* baseTokenOut */ )
    {
        // Check if under maintenance
        if (underMaintenance) revert UnderMaintenance();

        // Verify how many assets this amount of shares is worth
        // This assumes `takeAUMFees` was already called in the wrapping `Portfolio.redeem` call
        uint256 _amountAssets = convertToAssets(_amountShares);

        // Update pending asset amount to sell
        unchecked {
            // Unchecked: asset total supply is capped at type(uint256).max, so an individual balance will also never overflow
            pendingSaleAssets[Entity(payable(msg.sender))] += _amountAssets;
        }

        // Burn asset to maintain correct supply in portfolio's balance
        // This is important so AUM fees are charged proportional to the asset balance that still
        // belongs to the portfolio. This also implies that once an entity performs a redeem,
        // we won't charge/be entitled to any AUM fees on that portion of the assets.
        TPlusNAsset(receiptAsset).burn(_amountAssets);

        // Return the amount of assets out and 0 base token for a T+N redemption
        return (_amountAssets, 0);
    }

    /**
     * @notice Consolidates pending purchase balances into shares, based on the amount of assets effectively purchased.
     * @param _entity The entity whose pending balance should be consolidated.
     * @param _amountBaseToken The amount of base token to consolidate.
     * @param _amountAssets The amount of assets this amount of base token was capable of purchasing.
     * @dev The value of _amountAssets must be chosen carefully to avoid rounding errors e.g. 1 ether = 1 "real world" asset is a good choice.
     */
    function _consolidateDeposit(Entity _entity, uint256 _amountBaseToken, uint256 _amountAssets) private {
        // Decrease pending balance
        // Checked: we want to revert on underflow
        pendingPurchaseBalance[_entity] -= _amountBaseToken;

        // Mint shares proportional to the amount of assets produced
        // ⚠️ Share calculation must happen before all mints to avoid wrong values
        uint256 _amountShares = convertToShares(_amountAssets);
        _mint(address(_entity), _amountShares);

        // Mint the receipt asset equal to the amount of asset produced, since the portfolio
        // controls the supply of the receipt asset
        TPlusNAsset(receiptAsset).mint(address(this), _amountAssets);

        // Emit
        emit DepositConsolidated(_entity, _amountBaseToken, _amountAssets, _amountShares);
    }

    /**
     * @notice Consolidate pending sale/redeemed assets into base token, based on the amount of assets effectively sold. Transfers base token to entity.
     * @param _entity The entity whose pending asset balance should be consolidated.
     * @param _amountBaseToken The amount of base token the sale of the asset amount was capable of selling for.
     * @param _amountAssets The amount of assets that effectively got sold.
     * @dev Method will revert if portfolio does not have enough base token in its balance to transfer to entity and treasury.
     */
    function _consolidateRedeem(Entity _entity, uint256 _amountBaseToken, uint256 _amountAssets) private {
        // Checked: Desired underflow if larger
        pendingSaleAssets[_entity] -= _amountAssets;

        // Get net and fee values
        (uint256 _amountOut, uint256 _amountFee) = _calculateFee(_amountBaseToken, redemptionFee);

        // Transfer sale-produced base token amount to entity
        // Uses EBTT contract to circumvent any fee or events being triggered incorrectly
        ebtt.transferFromPortfolio(_entity, _amountOut);

        // Transfer fee to treasury
        baseToken.safeTransfer(feeTreasury, _amountFee);

        // Emit
        emit RedeemConsolidated(_entity, _amountOut, _amountAssets, _amountFee);
    }

    /**
     * @notice Consolidate pending balances into shares or base token, based on the amount of assets effectively purchased or sold.
     * @param _consolidations Array of `Consolidation` structs to process.
     */
    function _consolidate(Consolidation[] calldata _consolidations) private {
        for (uint256 i = 0; i < _consolidations.length; ++i) {
            if (_consolidations[i].operation == ConsolidationOperation.Deposit) {
                _consolidateDeposit(
                    _consolidations[i].entity, _consolidations[i].amountBaseToken, _consolidations[i].amountAssets
                );
            } else {
                _consolidateRedeem(
                    _consolidations[i].entity, _consolidations[i].amountBaseToken, _consolidations[i].amountAssets
                );
            }
        }
    }

    /**
     * @notice Perform consolidation while skipping any accrual operations.
     * @param _consolidations Array of `Consolidation` structs to process.
     * @dev Reverts if the contract does not have enough base token to transfer to the entity and treasury on a redeem consolidation.
     */
    function consolidateNoAccrual(Consolidation[] calldata _consolidations) external requiresAuth {
        // AUM fees must be taken whenever the balance of assets changes
        takeAumFees();
        // Consolidate
        _consolidate(_consolidations);
    }

    /**
     * @notice Endaoment role authed method to consolidate pending purchases and sales while distributing accrued assets.
     * @param _consolidations Array of `Consolidation` structs to process.
     * @param _accruedAssets Amount of assets accrued since last consolidation.
     * @dev Reverts if the contract does not have enough base token to transfer to the entity and treasury on a redeem consolidation.
     */
    function consolidateWithAccrual(Consolidation[] calldata _consolidations, uint256 _accruedAssets)
        external
        requiresAuth
    {
        // AUM fees must be taken whenever the balance of assets changes
        takeAumFees();

        // Given how the operational flow of how T+N works, accruals are simply the minting of the underlying asset
        // This *must* be done before any consolidation, to properly reflect the contribution of each existing entity's
        // position to produce the accrued assets
        TPlusNAsset(receiptAsset).mint(address(this), _accruedAssets);

        // Consolidate
        _consolidate(_consolidations);
    }

    /**
     * @notice Endaoment role authed method to mint shares to an entity. Used solely for correcting share balances in case of errors.
     * @param _entity The entity to mint shares to.
     * @param _amount The amount of shares to mint.
     * @dev This method is only callable by Endaoment roles, and used only in case of error corrections.
     */
    function correctionMint(Entity _entity, uint256 _amount) external requiresAuth {
        _mint(address(_entity), _amount);

        emit CorrectionShareMinted(_entity, _amount);
    }

    /**
     * @notice Endaoment role authed method to burn shares from an entity. Used solely for correcting share balances in case of errors.
     * @param _entity The entity to burn shares from.
     * @param _amount The amount of shares to burn.
     * @dev This method is only callable by Endaoment roles, and used only in case of error corrections.
     */
    function correctionBurn(Entity _entity, uint256 _amount) external requiresAuth {
        _burn(address(_entity), _amount);

        emit CorrectionShareBurned(_entity, _amount);
    }

    // @inheritdoc Portfolio
    function _exit(
        uint256,
        /* _amount */
        bytes calldata /* _data */
    ) internal pure override returns (uint256, /* actualAssetsOut */ uint256 /* baseTokenOut */ ) {
        // Noop
        return (0, 0);
    }

    /**
     * @notice Endaoment role authed method to set the processor address.
     * @param _processor Address to automatically route deposit base token to.
     */
    function setProcessor(address _processor) external requiresAuth {
        processor = _processor;
        emit ProcessorSet(_processor);
    }

    /**
     * @notice Role authed method to set the minimum base token amount allowed for a valid deposit.
     * @param _min Minimum base token amount allowed for a valid deposit.
     */
    function setMinDeposit(uint256 _min) external requiresAuth {
        minDeposit = _min;
        emit MinDepositSet(_min);
    }

    /**
     * @notice Role authed method to set the maintenance flag.
     * @param _underMaintenance Maintenance flag to pause functionality.
     */
    function setUnderMaintenance(bool _underMaintenance) external requiresAuth {
        underMaintenance = _underMaintenance;
        emit UnderMaintenanceSet(_underMaintenance);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.23;

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY,
        INVALID_MARKET_TYPE,
        TOO_LITTLE_INTEREST_RESERVE,
        NONZERO_INTEREST_BALANCE,
        LIQUIDATE_SEIZE_TOO_LITTLE
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    error Unauthorized();
    error InitializationFailed();

    error GetAccountSnapshotFailed(uint256 errorCode);

    error SeizePaused();
    error MintPaused();
    error BorrowPaused();
    error CollectInterestPaused();
    error PayInterestPaused();
    error TransferPaused();

    error InsufficientShortfall(uint errorCode, uint value);
    error InvalidTopUpLimit();
    error TopUpLimitExceeded();
    error TopUpZero();
    error SeizeFailed();
    error TopUpFailed();
    error LiquidateError();
    error LiquidateSeizeTooLittle();
    error LiquidateSeizeTooMuch();
    error LiquidateSeizeBellowMinValue(uint minSeizedValue, uint liquidatedValueTotal);
    error ExcessRefundFailed();
    error BorrowCapReached();
    error MarketAlreadyAdded();
    error InvalidInput();
    error OnlyAdminCanUnpause();
    error ChangeNotAuthorized();

    error MarketNotListed();
    error SameMarket();
    error WrongMarketType();
    error PriceError();
    error ComptrollerMismatch();
    error InvalidMarket();

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    uint public constant NO_ERROR = 0; // support legacy return codes

    error Unauthorized();
    error Unsupported();

    error AlreadyInitialized();
    error InitializeExchangeRateInvalid();
    error InitializeSetComptrollerFailed(uint256 errorCode);
    error InitializeSetInterestRateModelFailed(uint256 errorCode);
    error InitializeMarketTypeNotSet();
    error InitializeInvalidMarketType();
    error EnsureNonEmptyAmountTooSmall();

    error TransferComptrollerRejection(uint256 errorCode);
    error TransferNotAllowed();
    error TransferNotEnough();
    error TransferTooMuch();
    error TransferInvalidAmount();

    error TransferInFailed();
    error InsufficientBalanceAfterTransfer();
    error TransferOutFailed();
    error TransferFailed();
    error NftAmountTooHigh();
    error NftNotFound(uint256 nftId);

    error MintComptrollerRejection(uint256 errorCode);
    error MintFreshnessCheck();

    error RedeemComptrollerRejection(uint256 errorCode);
    error RedeemFreshnessCheck();
    error RedeemTransferOutNotPossible();
    error RedeemInvalidInputs();
    error RedeemTokensIsZero();

    error BorrowComptrollerRejection(uint256 errorCode);
    error BorrowFreshnessCheck();
    error BorrowCashNotAvailable();

    error RepayBorrowComptrollerRejection(uint256 errorCode);
    error RepayBorrowFreshnessCheck();
    error RepayTooHigh();

    error LiquidateComptrollerRejection(uint256 errorCode);
    error LiquidateFreshnessCheck();
    error LiquidateCollateralFreshnessCheck();
    error LiquidateAccrueBorrowInterestFailed(uint256 errorCode);
    error LiquidateAccrueCollateralInterestFailed(uint256 errorCode);
    error LiquidateLiquidatorIsBorrower();
    error LiquidateCloseAmountIsZero();
    error LiquidateCloseAmountIsUintMax();
    error LiquidateRepayBorrowFreshFailed(uint256 errorCode);

    error LiquidateSeizeComptrollerRejection(uint256 errorCode);
    error LiquidateSeizeLiquidatorIsBorrower();

    error AcceptAdminPendingAdminCheck();

    error SetComptrollerOwnerCheck();
    error SetPendingAdminOwnerCheck();

    error SetReserveFactorAdminCheck();
    error SetReserveFactorFreshCheck();
    error SetReserveFactorBoundsCheck();

    error AddReservesFactorFreshCheck(uint256 actualAddAmount);

    error ReduceReservesAdminCheck();
    error ReduceReservesFreshCheck();
    error ReduceReservesCashNotAvailable();
    error ReduceReservesCashValidation();

    error SetInterestRateModelOwnerCheck();
    error SetInterestRateModelFreshCheck();

    error SetProtocolSeizeShareAdminCheck();
    error SetProtocolSeizeShareTooHigh();

    error BorrowRateIsAbsurdlyHigh(uint borrowRateMantissa);

    error InvalidComptrollerAddress(address comptrollerAddress);
    error InvalidRateModelAddress(address interestRateModelAddress);

    error Reentry();

    error CannotSweepUnderlying();

    error CollectInterestFailed();
    error CollectInterestNotAllowed();
    error PayInterestNotAllowed();
    error InsufficientBalance();
    error PayInterestError();

    error SenderMismatch();
    error ValueMismatch();

    error PriceError();
}

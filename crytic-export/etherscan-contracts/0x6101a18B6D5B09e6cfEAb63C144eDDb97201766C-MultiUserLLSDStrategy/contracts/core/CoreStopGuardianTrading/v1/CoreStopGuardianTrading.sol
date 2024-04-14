// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { ICoreStopGuardianTradingV1 } from "./ICoreStopGuardianTradingV1.sol";

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { WithdrawalsDisabled, TradingDisabled, GlobalStopGuardianEnabled } from "../../libraries/DefinitiveErrors.sol";
import { IGlobalGuardian } from "../../../tools/GlobalGuardian/IGlobalGuardian.sol";

abstract contract CoreStopGuardianTrading is ICoreStopGuardianTradingV1, Context {
    address public constant GLOBAL_TRADE_GUARDIAN = 0x3AB7069fCB015Bd18d0542dA9deeDce3F4374aEE;

    bool public TRADING_GUARDIAN_TRADING_DISABLED;
    bool public TRADING_GUARDIAN_WITHDRAWALS_DISABLED;

    /// 0x49feb0371fc9661748a3d1bc01dbf9f5cdeb4102767351e1c6dd1f5d331acd6d
    bytes32 internal constant GLOBAL_TRADING_HASH = keccak256("TRADING");

    modifier tradingEnabled() {
        if (IGlobalGuardian(GLOBAL_TRADE_GUARDIAN).functionalityIsDisabled(GLOBAL_TRADING_HASH)) {
            revert GlobalStopGuardianEnabled();
        }

        if (TRADING_GUARDIAN_TRADING_DISABLED) {
            revert TradingDisabled();
        }
        _;
    }

    modifier withdrawalsEnabled() {
        if (TRADING_GUARDIAN_WITHDRAWALS_DISABLED) {
            revert WithdrawalsDisabled();
        }
        _;
    }

    function disableTrading() public virtual;

    function enableTrading() public virtual;

    function disableWithdrawals() public virtual;

    function enableWithdrawals() public virtual;

    function _disableTrading() internal {
        TRADING_GUARDIAN_TRADING_DISABLED = true;
        emit TradingDisabledUpdate(_msgSender(), true);
    }

    function _enableTrading() internal {
        delete TRADING_GUARDIAN_TRADING_DISABLED;
        emit TradingDisabledUpdate(_msgSender(), false);
    }

    function _disableWithdrawals() internal {
        TRADING_GUARDIAN_WITHDRAWALS_DISABLED = true;
        emit WithdrawalsDisabledUpdate(_msgSender(), true);
    }

    function _enableWithdrawals() internal {
        delete TRADING_GUARDIAN_WITHDRAWALS_DISABLED;
        emit WithdrawalsDisabledUpdate(_msgSender(), false);
    }
}

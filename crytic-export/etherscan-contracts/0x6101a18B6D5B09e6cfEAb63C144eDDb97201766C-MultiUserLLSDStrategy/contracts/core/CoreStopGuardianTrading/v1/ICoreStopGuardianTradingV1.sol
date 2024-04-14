// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

interface ICoreStopGuardianTradingV1 {
    event TradingDisabledUpdate(address indexed actor, bool indexed isEnabled);
    event WithdrawalsDisabledUpdate(address indexed actor, bool indexed isEnabled);
}

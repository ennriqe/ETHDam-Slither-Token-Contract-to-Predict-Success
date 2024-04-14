// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {MathUpgradeable} from "openzeppelin-contracts-upgradeable-v4.9.5/contracts/utils/math/MathUpgradeable.sol";

import {ApprovalSets, Count} from "./ApprovalSet.sol";

/**
 * [WARNING]
 * ====
 * Trying to delete this structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 * See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol for
 * more info.
 *
 * Call destructor() in order to safely destroy this structure
 * ====
 */
library MintPools {
    using ApprovalSets for ApprovalSets.Set;
    using MintPools for MintPools.Pool;

    struct Pool {
        Count _signatures;
        uint256 _threshold;
        uint256 _limit;
        uint256 _value;
        ApprovalSets.Set _refillApprovals;
    }

    error SpendAmountGreaterThanMintPoolThreshold(uint256 amount, uint256 mintPoolThreshold);
    error SpendAmountGreaterThanMintPoolValue(uint256 amount, uint256 mintPoolValue);
    error RefillApprovalsLessThanOtherPoolSignatures(Count approvals, Count signatures);
    error RefillPoolFromItself();
    error SignaturesGreaterThanMaxCount(Count signatures, Count maxCount);
    error ThresholdExceedsLimit(uint256 threshold, uint256 limit);

    function signatures(MintPools.Pool storage self) internal view returns (Count) {
        return self._signatures;
    }

    function threshold(MintPools.Pool storage self) internal view returns (uint256) {
        return self._threshold;
    }

    function limit(MintPools.Pool storage self) internal view returns (uint256) {
        return self._limit;
    }

    function value(MintPools.Pool storage self) internal view returns (uint256) {
        return self._value;
    }

    function refillApprovalsCount(
        MintPools.Pool storage self,
        function(address) view returns (bool) filter
    ) internal view returns (Count) {
        return self._refillApprovals.count(filter);
    }

    function refillApprovalAtIndex(
        MintPools.Pool storage self,
        Count refillApprovalIndex
    ) internal view returns (address) {
        return self._refillApprovals.at(refillApprovalIndex);
    }

    function setSignatures(MintPools.Pool storage self, Count signatures_) internal {
        if (signatures_ > ApprovalSets.MAX_COUNT) {
            revert SignaturesGreaterThanMaxCount(signatures_, ApprovalSets.MAX_COUNT);
        }
        self._signatures = signatures_;
    }

    function setThreshold(MintPools.Pool storage self, uint256 threshold_) internal {
        if (threshold_ > self.limit()) {
            revert ThresholdExceedsLimit(threshold_, self.limit());
        }
        self._threshold = threshold_;
    }

    function setLimit(MintPools.Pool storage self, uint256 limit_) internal {
        if (limit_ < self.threshold()) {
            revert ThresholdExceedsLimit(self.threshold(), limit_);
        }
        self._limit = limit_;
        self._value = MathUpgradeable.min(self._value, limit_);
    }

    function spend(MintPools.Pool storage self, uint256 amount) internal {
        assert(self._value <= self._limit);
        if (amount > self._threshold) {
            revert SpendAmountGreaterThanMintPoolThreshold(amount, self._threshold);
        }
        if (amount > self._value) {
            revert SpendAmountGreaterThanMintPoolValue(amount, self._value);
        }
        self._value -= amount;
    }

    function approveRefillFromPool(MintPools.Pool storage self, address ratifier) internal {
        self._refillApprovals.add(ratifier);
    }

    function finalizeRefillFromPool(
        MintPools.Pool storage self,
        MintPools.Pool storage other,
        function(address) view returns (bool) filter
    ) internal {
        if (self.eq(other)) {
            revert RefillPoolFromItself();
        }
        if (self._refillApprovals.count(filter) < other._signatures) {
            revert RefillApprovalsLessThanOtherPoolSignatures(self._refillApprovals.count(filter), other._signatures);
        }
        self._refillApprovals.removeAll();

        assert(self._value <= self._limit);
        uint256 refillAmount = self._limit - self._value;
        other.spend(refillAmount);
        self._value += refillAmount;
        assert(self._value == self._limit);
    }

    function refillFromAdmin(MintPools.Pool storage self) internal {
        self._value = self._limit;
    }

    function destructor(MintPools.Pool storage self) internal {
        self._refillApprovals.removeAll();
    }

    function eq(MintPools.Pool storage self, MintPools.Pool storage other) internal pure returns (bool) {
        bool slotEq;
        assembly {
            slotEq := eq(self.slot, other.slot)
        }
        return slotEq;
    }
}

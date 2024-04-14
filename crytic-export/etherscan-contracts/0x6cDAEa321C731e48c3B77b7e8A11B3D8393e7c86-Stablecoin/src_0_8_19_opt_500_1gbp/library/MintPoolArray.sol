// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ApprovalSets, Count} from "./ApprovalSet.sol";
import {MintPools} from "./MintPool.sol";

type PoolIndex is uint256;

using {lt as <, gt as >} for PoolIndex global;

function lt(PoolIndex self, PoolIndex other) pure returns (bool) {
    return PoolIndex.unwrap(self) < PoolIndex.unwrap(other);
}

function gt(PoolIndex self, PoolIndex other) pure returns (bool) {
    return PoolIndex.unwrap(self) > PoolIndex.unwrap(other);
}

library PoolIndices {
    PoolIndex internal constant ZERO = PoolIndex.wrap(0);

    function prev(PoolIndex self) internal pure returns (PoolIndex) {
        return PoolIndex.wrap(PoolIndex.unwrap(self) - 1);
    }

    function next(PoolIndex self) internal pure returns (PoolIndex) {
        return PoolIndex.wrap(PoolIndex.unwrap(self) + 1);
    }
}

library MintPoolArrays {
    using MintPools for MintPools.Pool;
    using MintPoolArrays for MintPoolArrays.Array;
    using PoolIndices for PoolIndex;

    struct Array {
        MintPools.Pool[] _array;
    }

    error PoolSignaturesLessThanPreviousPoolSignatures(Count signatures, Count prevSignatures);
    error PoolSignaturesGreaterThanNextPoolSignatures(Count signatures, Count nextSignatures);
    error PoolThresholdLessThanPreviousPoolThreshold(uint256 threshold, uint256 prevThreshold);
    error PoolThresholdGreaterThanNextPoolThreshold(uint256 threshold, uint256 nextThreshold);
    error PoolThresholdLessThanPreviousPoolLimit(uint256 threshold, uint256 prevLimit);
    error PoolLimitLessThanPreviousPoolLimit(uint256 limit, uint256 prevLimit);
    error PoolLimitGreaterThanNextPoolLimit(uint256 limit, uint256 nextLimit);
    error PoolLimitGreaterThanNextPoolThreshold(uint256 limit, uint256 nextThreshold);

    function at(MintPoolArrays.Array storage self, PoolIndex poolIndex) internal view returns (MintPools.Pool storage) {
        return self._array[PoolIndex.unwrap(poolIndex)];
    }

    function length(MintPoolArrays.Array storage self) internal view returns (PoolIndex) {
        return PoolIndex.wrap(self._array.length);
    }

    function push(MintPoolArrays.Array storage self) internal {
        MintPools.Pool storage last = self._array.push();
        last.setLimit(type(uint256).max);
        last.setThreshold(type(uint256).max);
        last.setSignatures(ApprovalSets.MAX_COUNT);
    }

    function pop(MintPoolArrays.Array storage self) internal {
        self._array[self._array.length - 1].destructor();
        self._array.pop();
    }

    function setSignatures(MintPoolArrays.Array storage self, PoolIndex poolIndex, Count signatures) internal {
        if (poolIndex > PoolIndices.ZERO && signatures < self.at(poolIndex.prev()).signatures()) {
            revert PoolSignaturesLessThanPreviousPoolSignatures(signatures, self.at(poolIndex.prev()).signatures());
        }
        if (poolIndex.next() < self.length() && signatures > self.at(poolIndex.next()).signatures()) {
            revert PoolSignaturesGreaterThanNextPoolSignatures(signatures, self.at(poolIndex.next()).signatures());
        }
        self.at(poolIndex).setSignatures(signatures);
    }

    function setThreshold(MintPoolArrays.Array storage self, PoolIndex poolIndex, uint256 threshold) internal {
        if (poolIndex > PoolIndices.ZERO && threshold < self.at(poolIndex.prev()).threshold()) {
            revert PoolThresholdLessThanPreviousPoolThreshold(threshold, self.at(poolIndex.prev()).threshold());
        }
        if (poolIndex > PoolIndices.ZERO && threshold < self.at(poolIndex.prev()).limit()) {
            revert PoolThresholdLessThanPreviousPoolLimit(threshold, self.at(poolIndex.prev()).limit());
        }
        if (poolIndex.next() < self.length() && threshold > self.at(poolIndex.next()).threshold()) {
            revert PoolThresholdGreaterThanNextPoolThreshold(threshold, self.at(poolIndex.next()).threshold());
        }
        self.at(poolIndex).setThreshold(threshold);
    }

    function setLimit(MintPoolArrays.Array storage self, PoolIndex poolIndex, uint256 limit) internal {
        if (poolIndex > PoolIndices.ZERO && limit < self.at(poolIndex.prev()).limit()) {
            revert PoolLimitLessThanPreviousPoolLimit(limit, self.at(poolIndex.prev()).limit());
        }
        if (poolIndex.next() < self.length() && limit > self.at(poolIndex.next()).limit()) {
            revert PoolLimitGreaterThanNextPoolLimit(limit, self.at(poolIndex.next()).limit());
        }
        if (poolIndex.next() < self.length() && limit > self.at(poolIndex.next()).threshold()) {
            revert PoolLimitGreaterThanNextPoolThreshold(limit, self.at(poolIndex.next()).threshold());
        }
        self.at(poolIndex).setLimit(limit);
    }
}

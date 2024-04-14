// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// solhint-disable-next-line max-line-length
import {EnumerableSetUpgradeable} from "openzeppelin-contracts-upgradeable-v4.9.5/contracts/utils/structs/EnumerableSetUpgradeable.sol";

type Count is uint256;

using {lt as <, lte as <=, eq as ==, gte as >=, gt as >} for Count global;

function lt(Count self, Count other) pure returns (bool) {
    return Count.unwrap(self) < Count.unwrap(other);
}

function lte(Count self, Count other) pure returns (bool) {
    return Count.unwrap(self) <= Count.unwrap(other);
}

function eq(Count self, Count other) pure returns (bool) {
    return Count.unwrap(self) == Count.unwrap(other);
}

function gte(Count self, Count other) pure returns (bool) {
    return Count.unwrap(self) >= Count.unwrap(other);
}

function gt(Count self, Count other) pure returns (bool) {
    return Count.unwrap(self) > Count.unwrap(other);
}

/**
 * [WARNING]
 * ====
 * Trying to delete this structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 * See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol for
 * more info.
 *
 * Call removeAll() in order to safely destroy this structure
 * ====
 */
library ApprovalSets {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    Count internal constant MAX_COUNT = Count.wrap(8);

    struct Set {
        EnumerableSetUpgradeable.AddressSet _approvalSet;
    }

    error ApprovalsCountAboveLimit();
    error ApprovalAlreadyPresentInSet(address address_);

    function at(Set storage self, Count index_) internal view returns (address) {
        return self._approvalSet.at(Count.unwrap(index_));
    }

    function count(Set storage self, function(address) view returns (bool) filter) internal view returns (Count) {
        uint256 length = self._approvalSet.length();
        assert(Count.wrap(length) <= MAX_COUNT);
        uint256 result = 0;
        for (uint256 i; i < length; i++) {
            if (filter(self._approvalSet.at(i))) {
                result++;
            }
        }
        return Count.wrap(result);
    }

    function add(Set storage self, address address_) internal {
        if (Count.wrap(self._approvalSet.length()) >= MAX_COUNT) {
            revert ApprovalsCountAboveLimit();
        }
        if (!self._approvalSet.add(address_)) {
            revert ApprovalAlreadyPresentInSet(address_);
        }
    }

    function removeAll(Set storage self) internal {
        for (uint256 i = self._approvalSet.length(); i > 0; i--) {
            assert(self._approvalSet.remove(self._approvalSet.at(i - 1)));
        }
    }
}

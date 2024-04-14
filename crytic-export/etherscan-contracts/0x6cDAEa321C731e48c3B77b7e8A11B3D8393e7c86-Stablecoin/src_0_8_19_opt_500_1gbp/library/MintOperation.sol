// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ApprovalSets, Count} from "./ApprovalSet.sol";

/**
 * [WARNING]
 * ====
 * Trying to delete this structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 * See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol for
 * more info.
 * ====
 */
library MintOperations {
    using ApprovalSets for ApprovalSets.Set;
    using MintOperations for MintOperations.Op;

    enum Status {
        None,
        Requested,
        Finalized,
        Revoked
    }

    struct Op {
        Status _status;
        address _to;
        uint256 _value;
        ApprovalSets.Set _ratifierApprovals;
    }

    error RatifierApprovalsLessThanRequiredApprovals(Count ratifierApprovals, Count requiredApprovals);
    error CurrentStatusIsNotRequiredStatus(Status currentStatus, Status requiredStatus);
    error MintRequestReceiverIsAddressZero();
    error MintRequestAmountIsZero();

    modifier onlyStatus(MintOperations.Op storage self, Status requiredStatus) {
        if (self._status != requiredStatus) {
            revert CurrentStatusIsNotRequiredStatus(self._status, requiredStatus);
        }
        _;
    }

    function status(MintOperations.Op storage self) internal view returns (Status) {
        return self._status;
    }

    function to(MintOperations.Op storage self) internal view returns (address) {
        return self._to;
    }

    function value(MintOperations.Op storage self) internal view returns (uint256) {
        return self._value;
    }

    function ratifierApprovals(
        MintOperations.Op storage self,
        function(address) view returns (bool) filter
    ) internal view returns (Count) {
        return self._ratifierApprovals.count(filter);
    }

    function ratifierApprovalAtIndex(
        MintOperations.Op storage self,
        Count ratifierApprovalIndex
    ) internal view returns (address) {
        return self._ratifierApprovals.at(ratifierApprovalIndex);
    }

    function request(
        MintOperations.Op storage self,
        address to_,
        uint256 value_
    ) internal onlyStatus(self, Status.None) {
        assert(self._to == address(0));
        assert(self._value == 0);
        if (to_ == address(0)) {
            revert MintRequestReceiverIsAddressZero();
        }
        if (value_ == 0) {
            revert MintRequestAmountIsZero();
        }
        self._status = Status.Requested;
        self._to = to_;
        self._value = value_;
    }

    function approve(MintOperations.Op storage self, address ratifier) internal onlyStatus(self, Status.Requested) {
        self._ratifierApprovals.add(ratifier);
    }

    function finalize(
        MintOperations.Op storage self,
        Count requiredApprovals,
        function(address) view returns (bool) filter
    ) internal onlyStatus(self, Status.Requested) {
        if (self._ratifierApprovals.count(filter) < requiredApprovals) {
            revert RatifierApprovalsLessThanRequiredApprovals(self._ratifierApprovals.count(filter), requiredApprovals);
        }
        self._status = MintOperations.Status.Finalized;
    }

    function revoke(MintOperations.Op storage self) internal onlyStatus(self, Status.Requested) {
        self._status = MintOperations.Status.Revoked;
    }
}

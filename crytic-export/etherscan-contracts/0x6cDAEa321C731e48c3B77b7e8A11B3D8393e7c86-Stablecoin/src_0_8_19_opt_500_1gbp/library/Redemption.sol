// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Redemption {
    using Redemption for Redemption.Params;

    struct Params {
        uint256 _min;
        uint256[49] __gap;
    }

    error RedemptionAmountLessThanMin(uint256 amount, uint256 min);

    function min(Redemption.Params storage self) internal view returns (uint256) {
        return self._min;
    }

    function checkRedemption(Redemption.Params storage self, uint256 amount) internal view {
        if (amount < self._min) {
            revert RedemptionAmountLessThanMin(amount, self._min);
        }
    }

    function setMin(Redemption.Params storage self, uint256 min_) internal {
        self._min = min_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AggregatorV3Interface} from "chainlink-v2.7.2/src/v0.8/interfaces/AggregatorV3Interface.sol";

library ProofOfReserve {
    using ProofOfReserve for ProofOfReserve.Params;

    struct Params {
        bool _enabled;
        AggregatorV3Interface _feed;
        uint8 _decimals;
        uint256 _heartbeat;
        uint256[48] __gap;
    }

    error ProofOfReserveFeedIsAddressZero();
    error ProofOfReserveHeartbeatIsZero();

    error ProofOfReserveFeedDecimalsDoNotMatch(uint8 chainReserveFeedDecimals, uint8 paramsDecimals);
    error ProofOfReserveFeedSignedReservesLessThanOrEqualToZero(int256 signedReserves);
    error ProofOfReserveFeedUpdatedAfterBlockTimestamp(uint256 updatedAt, uint256 blockTimestamp);
    error ProofOfReserveFeedUpdatedBeforeHeartbeat(uint256 updatedAtPlusHeartbeat, uint256 blockTimestamp);
    error ProofOfReserveTotalSupplyAfterMintWouldExceedReserves(uint256 totalSupplyAfterMint, uint256 reserves);

    function enabled(ProofOfReserve.Params storage self) internal view returns (bool) {
        return self._enabled;
    }

    function feed(ProofOfReserve.Params storage self) internal view returns (AggregatorV3Interface) {
        return self._feed;
    }

    function decimals(ProofOfReserve.Params storage self) internal view returns (uint8) {
        return self._decimals;
    }

    function heartbeat(ProofOfReserve.Params storage self) internal view returns (uint256) {
        return self._heartbeat;
    }

    function checkMint(ProofOfReserve.Params storage self, uint256 amount, uint256 totalSupply) internal view {
        if (!self._enabled || address(self._feed) == address(0)) {
            return;
        }
        if (self._feed.decimals() != self._decimals) {
            revert ProofOfReserveFeedDecimalsDoNotMatch(self._feed.decimals(), self._decimals);
        }
        // slither-disable-next-line unused-return
        (, int256 signedReserves, , uint256 updatedAt, ) = self._feed.latestRoundData();
        if (signedReserves <= 0) {
            revert ProofOfReserveFeedSignedReservesLessThanOrEqualToZero(signedReserves);
        }
        uint256 reserves = uint256(signedReserves);
        if (updatedAt > block.timestamp) {
            revert ProofOfReserveFeedUpdatedAfterBlockTimestamp(updatedAt, block.timestamp);
        }
        if (updatedAt + self._heartbeat < block.timestamp) {
            revert ProofOfReserveFeedUpdatedBeforeHeartbeat(updatedAt + self._heartbeat, block.timestamp);
        }
        if (totalSupply + amount > reserves) {
            revert ProofOfReserveTotalSupplyAfterMintWouldExceedReserves(totalSupply + amount, reserves);
        }
    }

    function setEnabled(ProofOfReserve.Params storage self, bool enabled_) internal {
        if (enabled_) {
            if (address(self._feed) == address(0)) {
                revert ProofOfReserveFeedIsAddressZero();
            }
            if (self._heartbeat == 0) {
                revert ProofOfReserveHeartbeatIsZero();
            }
        }
        self._enabled = enabled_;
    }

    function setFeed(ProofOfReserve.Params storage self, AggregatorV3Interface feed_) internal {
        self._feed = feed_;
        if (address(feed_) == address(0)) {
            self.setEnabled(false);
        }
    }

    function setDecimals(ProofOfReserve.Params storage self, uint8 decimals_) internal {
        self._decimals = decimals_;
    }

    function setHeartbeat(ProofOfReserve.Params storage self, uint256 heartbeat_) internal {
        self._heartbeat = heartbeat_;
        if (heartbeat_ == 0) {
            self.setEnabled(false);
        }
    }
}

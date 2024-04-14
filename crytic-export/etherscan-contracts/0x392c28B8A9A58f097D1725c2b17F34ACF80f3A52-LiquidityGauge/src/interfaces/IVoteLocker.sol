// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IVoteLocker {
    struct LockedBalance {
        uint208 amount;
        uint48 unlockTime;
    }

    struct Epoch {
        uint208 supply; //epoch boosted supply
        uint48 date; //epoch start date
    }

    function balanceOf(address _account) external view returns (uint256 amount);

    function totalSupply() external view returns (uint256 amount);

    function lockedBalances(address _user)
        external
        view
        returns (uint256 total, uint256 unlockable, uint256 locked, LockedBalance[] memory lockData);

    function lock(address _account, uint256 _amount) external;

    function checkpointEpoch() external;

    function epochCount() external view returns (uint256);

    function epochs(uint256 i) external view returns (Epoch memory);

    function balanceAtEpochOf(uint256 _epoch, address _user)
        external
        view
        returns (uint256 amount);

    function totalSupplyAtEpoch(uint256 _epoch) external view returns (uint256 supply);

    function queueNewRewards(address _rewardsToken, uint256 reward) external;

    function getReward(address _account, bool _stake) external;

    function getReward(address _account) external;
}

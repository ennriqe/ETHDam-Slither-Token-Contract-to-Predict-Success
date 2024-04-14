pragma solidity ^0.8.0;

interface IStaking {
    function init(address, address, address) external;

    function deposit(uint256 _amount) external payable;

    function withdraw() external;

    function claim() external;

    function pending(address _who) external view returns (uint256);

    function updateReward(uint256 _amount) external;
}
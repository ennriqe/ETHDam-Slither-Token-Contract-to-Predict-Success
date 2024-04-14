// SPDX-License-Identifier: MIT
// Akko Protocol - 2024
pragma solidity ^0.8.20;

interface IVault {
    function depositToForwardAddr(
        uint32 _preferredProtocol
    ) external payable returns (uint256);

    function depositToForwardAddr(
        uint32 _preferredProtocol,
        address _referral
    ) external payable returns (uint256);

    function deposit() external payable returns (uint256);

    function setForwardingContract(
        address payable _forwardingContract
    ) external;

    function sharesForAmount(uint256 _amount) external view returns (uint256);

    function amountForShare(uint256 _share) external view returns (uint256);

    function getTotalEtherClaimOf(
        address _user
    ) external view returns (uint256);

    function getTotalPooledEther() external view returns (uint256);

    function getBalance() external view returns (uint256);
}

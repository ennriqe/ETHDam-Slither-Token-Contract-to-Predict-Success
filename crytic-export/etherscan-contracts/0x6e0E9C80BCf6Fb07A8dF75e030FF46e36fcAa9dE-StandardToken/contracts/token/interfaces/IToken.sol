// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IToken is IERC20MetadataUpgradeable {

    struct Taxes {
        uint256 marketing;
        uint256 reflection;
    }

    struct TokenData {
        string name;
        string symbol;
        uint8 decimals;
        uint256 supply;
        address routerAddress;
        address karmaDeployer;
        Taxes buyTax;
        Taxes sellTax;
        address marketingWallet;
        address rewardToken;
    }

    function initialize(TokenData memory tokenData) external;

    function updateExcludedFromFees(address _address, bool state) external;
    function excludedFromFees(address _address) external view returns (bool);

    function getOwner() external view returns (address);
}

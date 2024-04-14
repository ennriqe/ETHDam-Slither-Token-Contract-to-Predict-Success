// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.23;

abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function autoEnterMarkets(address account) virtual external;
    function autoExitMarkets(address account) virtual external;
    function enterMarkets(address[] calldata cTokens) virtual external returns (uint[] memory);
    function exitMarket(address cToken) virtual external returns (uint);
    function redeemAllInterest(address lender, address[] memory cTokens) virtual external returns (uint[] memory);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) virtual external returns (uint);

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) virtual external returns (uint);

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) virtual external returns (uint);

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) virtual external returns (uint);

    function collectInterestAllowed(
        address cTokenInterestMarket,
        address cTokenSupplyMarket,
        address lender,
        uint interestAmount) virtual external returns (uint);

    function payInterestAllowed(
        address cTokenInterestMarket,
        address cTokenBorrowMarket,
        address payer,
        uint payTokens) virtual external returns (uint);

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) virtual external returns (uint);

    function isListed(address cToken) virtual external view returns (bool);

    function getAssetsExchangeRate(address cTokenA, address cTokenB) virtual external view returns (uint);

    function _checkEoaOrWL(address msgSender) virtual external view returns (bool);

    /*** Liquidity/Liquidation Calculations ***/

    struct Liquidatables {
        address cToken; // token to liquidate
        uint amount;    // non-NFT markets
        uint[] nftIds;  // NFT markets
    }

    function topUpInterestShortfall(address borrower, uint maxTopUpTokens, address cTokenCollateral) virtual external returns (uint[2] memory);

    function batchLiquidateBorrow(address borrower, Liquidatables[] memory liquidatables, address[] memory cTokenCollaterals, uint minSeizedValue) virtual external returns (uint[][2] memory results);

    function liquidateCalculateSeizeTokensNormed(address cTokenCollateral, uint normedRepayAmount) virtual public view returns (uint);

    function interestMarket() virtual external view returns (address);
}

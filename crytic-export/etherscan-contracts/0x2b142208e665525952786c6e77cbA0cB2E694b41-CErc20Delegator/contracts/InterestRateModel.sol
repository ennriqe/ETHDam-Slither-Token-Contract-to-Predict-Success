// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.23;

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) virtual public view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) virtual public view returns (uint);

    /**
     * @notice Calculates the current borrow and supply rate per block
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @param reserveFactorMantissa The current reserve factor for the market
     * @return (uint, uint) The borrow rate percentage per block as a mantissa (scaled by BASE),
     *         supply rate percentage per block as a mantissa (scaled by BASE)
     */
    function getMarketRates(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) virtual public view returns (uint, uint) {
      return (getBorrowRate(cash, borrows, reserves), getSupplyRate(cash, borrows, reserves, reserveFactorMantissa));
    }
}

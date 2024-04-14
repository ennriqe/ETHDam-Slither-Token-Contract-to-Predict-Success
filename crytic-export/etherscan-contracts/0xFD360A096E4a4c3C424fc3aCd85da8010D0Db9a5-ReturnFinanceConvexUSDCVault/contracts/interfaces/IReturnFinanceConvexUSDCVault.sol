// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReturnFinanceConvexUSDCVault {
    struct Config {
        IERC20 usdc;
        address cvx;
        address crv;
        address curveLpToken;
        address curveDepositZap;
        address convexBooster;
        address convexRewards;
        address convexHandler;
        uint256 convexPoolId;
        uint24 uniswapFee;
        address uniswapV3Router;
        address chainlinkDataFeedCVXUSD;
        address chainlinkDataFeedCRVUSD;
    }

    event SweepFunds(address token, uint256 amount);
    event PoolDonation(address sender, uint256 value);
    event AddressWhitelisted(address whitelistedAddress, bool isWhitelisted);
    event RescueFunds(uint256 totalUsdc);
    event RescueRewards(uint256 crvRewards, uint256 cvxRewards);
    event SlippageUpdated(uint256 newSlippage);
    event SetHarvestRewards(bool harvest);
    event HarvestRewards(uint256 amount);
    event SwapFeeUpdated(uint24 newSwapFee);

    function sweepFunds(address token) external;
    function rescueFunds(address destination) external;
    function toggleWhitelist(address updatedAddress, bool isWhitelisted) external;

    error UnableToSweep(address token);
    error NotInWhitelist(address wrongAddress);
    error ChainlinkPriceZero();
    error ChainlinkIncompleteRound();
    error ChainlinkStalePrice();
}

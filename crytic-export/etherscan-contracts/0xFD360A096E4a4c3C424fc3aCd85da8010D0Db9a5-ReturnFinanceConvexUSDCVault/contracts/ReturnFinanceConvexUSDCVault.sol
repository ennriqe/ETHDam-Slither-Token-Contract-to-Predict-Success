// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {IConvexBooster} from "./interfaces/IConvexBooster.sol";
import {IConvexHandler} from "./interfaces/IConvexHandler.sol";
import {ICurvePool} from "./interfaces/ICurvePool.sol";
import {BaseRewardPool} from "./interfaces/BaseRewardPool.sol";
import {I3CrvMetaPoolZap} from "./interfaces/IMetaPoolZap.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {IReturnFinanceConvexUSDCVault} from "./interfaces/IReturnFinanceConvexUSDCVault.sol";

/**
 * @title Return Finance Convex USDC Vault
 * @author 0xFusion (https://0xfusion.com)
 * @dev Return Finance Convex USDC Vault is an ERC4626 compliant vault.
 * @dev The ERC4626 "Tokenized Vault Standard" is defined in https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 */
contract ReturnFinanceConvexUSDCVault is IReturnFinanceConvexUSDCVault, ERC4626, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    /* ========== STATE VARIABLES ========== */

    address public immutable usdc;
    address public immutable cvx;
    address public immutable crv;
    address public immutable curveLpToken;
    address public immutable curveDepositZap;
    address public immutable convexBooster;
    address public immutable convexRewards;
    address public immutable convexHandler;
    address public immutable uniswapV3Router;
    address public immutable chainlinkDataFeedCVXUSD;
    address public immutable chainlinkDataFeedCRVUSD;

    uint256 public immutable convexPoolId;
    uint24 public uniswapFee;

    /**
     * @notice Represents the whitelist of addresses that can interact with this contract
     */
    mapping(address => bool) public whitelist;

    /**
     * @notice Function to receive ether, which emits a donation event
     */
    receive() external payable {
        emit PoolDonation(_msgSender(), msg.value);
    }

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor to initialize the Return Finance Convex USDC Vault.
     * @param config Configuration struct
     */
    constructor(Config memory config)
        Ownable(_msgSender())
        ERC4626(config.usdc)
        ERC20("Return Finance Convex USDC Vault", "rfCvxUSDC")
    {
        usdc = address(config.usdc);
        cvx = config.cvx;
        crv = config.crv;
        curveLpToken = config.curveLpToken;
        curveDepositZap = config.curveDepositZap;
        convexBooster = config.convexBooster;
        convexRewards = config.convexRewards;
        convexHandler = config.convexHandler;
        convexPoolId = config.convexPoolId;
        uniswapFee = config.uniswapFee;
        uniswapV3Router = config.uniswapV3Router;
        chainlinkDataFeedCVXUSD = config.chainlinkDataFeedCVXUSD;
        chainlinkDataFeedCRVUSD = config.chainlinkDataFeedCRVUSD;
    }

    /* ========== VIEWS ========== */

    /**
     * @dev See {IERC4626-totalAssets}.
     * @notice The sum of total assets controlled by the vault is calclulated as follows:
     * ::Curve LP tokens staked in Convex and denominated in USDC
     * ::USDC in the vault (if any)
     * ::Accrued CRV denomiated in USD
     * ::Accrued CVX denominated in USD
     * The amount is reduced by 1%, to account for Uniswap fees/slippage
     */
    function totalAssets() public view override returns (uint256) {
        return (
            (stakedLpInConvex() * ICurvePool(curveLpToken).get_virtual_price() / 1e30)
                + IERC20(usdc).balanceOf(address(this)) + (earnedCVX() * uint256(cvxPriceUSD()) / 1e20)
                + (earnedCRV() * uint256(crvPriceUSD()) / 1e20)
        ) * (1000000 - uniswapFee) / 1000000;
    }

    /**
     * @notice The staked Curve LP tokens in Convex
     * @return The amount of staked Curve LP tokens in Convex Finance
     */
    function stakedLpInConvex() public view returns (uint256) {
        return BaseRewardPool(convexRewards).balanceOf(address(this));
    }

    /**
     * @notice The accrued CVX rewards from staking Curve LP tokens in Convex Finance
     * @return The amount of CVX rewards accrued in the protocol
     */
    function earnedCVX() public view returns (uint256) {
        return IConvexHandler(convexHandler).computeClaimableConvex(earnedCRV());
    }

    /**
     * @notice The accrued CRV rewards from staking Curve LP tokens in Convex Finance
     * @return The amount of CRV rewards accrued in the protocol
     */
    function earnedCRV() public view returns (uint256) {
        return BaseRewardPool(convexRewards).earned(address(this));
    }

    /**
     * @notice The CRV/USD price
     * @return The price of CRV denominated in USD
     */
    function crvPriceUSD() public view returns (int256) {
        (uint80 roundId, int256 answer, uint256 startedAt,, uint80 answeredInRound) =
            AggregatorV3Interface(chainlinkDataFeedCRVUSD).latestRoundData();
        if (answer <= 0) revert ChainlinkPriceZero();
        if (startedAt == 0) revert ChainlinkIncompleteRound();
        if (answeredInRound < roundId) revert ChainlinkStalePrice();

        return answer;
    }

    /**
     * @notice The CVX/USD price
     * @return The price of CVX denominated in USD
     */
    function cvxPriceUSD() public view returns (int256) {
        (uint80 roundId, int256 answer, uint256 startedAt,, uint80 answeredInRound) =
            AggregatorV3Interface(chainlinkDataFeedCVXUSD).latestRoundData();
        if (answer <= 0) revert ChainlinkPriceZero();
        if (startedAt == 0) revert ChainlinkIncompleteRound();
        if (answeredInRound < roundId) revert ChainlinkStalePrice();

        return answer;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Send all tokens or ETH held by the contract to the owner
     * @param token The token to sweep, or 0 for ETH
     */
    function sweepFunds(address token) external onlyOwner {
        if (token == address(0)) {
            (bool success,) = owner().call{value: address(this).balance}("");
            if (!success) revert UnableToSweep(token);
            emit SweepFunds(token, address(this).balance);
        } else {
            IERC20(token).safeTransfer(owner(), IERC20(token).balanceOf(address(this)));
            emit SweepFunds(token, IERC20(token).balanceOf(address(this)));
        }
    }

    /**
     * @notice Rescue any locked funds from the pools
     * @param destination The address where the funds should be sent
     */
    function rescueFunds(address destination) external onlyOwner {
        uint256 totalLP = stakedLpInConvex();
        BaseRewardPool(convexRewards).withdrawAndUnwrap(totalLP, false);
        IERC20(curveLpToken).safeTransfer(destination, totalLP);

        emit RescueFunds(totalLP);
    }

    /**
     * @notice Rescue any locked rewards
     * @param destination The address where the funds should be sent
     */
    function rescueRewards(address destination) external onlyOwner {
        // Claim pending CVX and CRV rewards from Convex
        BaseRewardPool(convexRewards).getReward();

        uint256 crvRewards = IERC20(crv).balanceOf(address(this));
        uint256 cvxRewards = IERC20(cvx).balanceOf(address(this));

        IERC20(crv).safeTransfer(destination, crvRewards);
        IERC20(cvx).safeTransfer(destination, cvxRewards);

        emit RescueRewards(crvRewards, cvxRewards);
    }

    /**
     * @notice Updates the swap fee used in _swap and totalAssets calculation
     * @param newSwapFee The new swap fee
     */
    function updateSwapFee(uint24 newSwapFee) external onlyOwner {
        uniswapFee = newSwapFee;

        emit SwapFeeUpdated(newSwapFee);
    }

    /**
     * @notice Allow or disallow an address to interact with the contract
     * @param updatedAddress The address to change the whitelist status for
     * @param isWhitelisted Whether the address should be whitelisted
     */
    function toggleWhitelist(address updatedAddress, bool isWhitelisted) external onlyOwner {
        whitelist[updatedAddress] = isWhitelisted;

        emit AddressWhitelisted(updatedAddress, isWhitelisted);
    }

    /**
     * @notice Allow the owner to call an external contract for some reason. E.g. claim an airdrop.
     * @param target The target contract address
     * @param data Encoded function data
     */
    function callExternalContract(address target, bytes memory data) external onlyOwner {
        target.functionCall(data);
    }

    /**
     * @notice Swap function for the underlying token (USDC) and DAI
     * @param tokenIn The address of the token to be swapped
     * @param tokenOut The address of the token to be received
     * @param amountIn The amount of token to be swapped
     * @param amountOutMinimum The minimum amount of token to be received
     * @param swapFee The swap fee
     * @return amountOut The amount of tokens received from the swap
     */
    function _swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMinimum, uint24 swapFee)
        internal
        returns (uint256 amountOut)
    {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: swapFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        amountOut = ISwapRouter(uniswapV3Router).exactInputSingle(params);
    }

    /**
     * @notice Claims accrued CRV and CVX rewards and swaps them for USDC on Uniswap V3
     * @return harvestAmount The amount harvested denominated in USDC
     */
    function harvestRewards() public returns (uint256 harvestAmount) {
        if (!whitelist[_msgSender()]) revert NotInWhitelist(_msgSender());

        // Claim pending CVX and CRV rewards from Convex Finance
        BaseRewardPool(convexRewards).getReward();

        uint256 crvRewards = IERC20(crv).balanceOf(address(this));
        uint256 cvxRewards = IERC20(cvx).balanceOf(address(this));

        // Swap only if there's anything to swap
        if (crvRewards > 0 && cvxRewards > 0) {
            // Approve Uniswap V3 Router to move CRV and CVX
            IERC20(crv).approve(uniswapV3Router, crvRewards);
            IERC20(cvx).approve(uniswapV3Router, cvxRewards);
            // Swap CRV and CVX for USDC
            uint256 usdcReceivedFromCRV = _swap(crv, usdc, crvRewards, 0, uniswapFee);
            uint256 usdcReceivedFromCVX = _swap(cvx, usdc, cvxRewards, 0, uniswapFee);

            harvestAmount = usdcReceivedFromCRV + usdcReceivedFromCVX;

            emit HarvestRewards(harvestAmount);
        }
    }
    /**
     * @notice Harvests rewards and deposits back to Convex
     * @return harvestAmount The amount harvested denominated in USDC
     */

    function harvestAndDepositRewards() external returns (uint256 harvestAmount) {
        harvestAmount = harvestRewards();
        _afterDepositOrWithdraw();
    }

    /**
     * @notice Hook called before a user withdraws USDC from the vault.
     */
    function _beforeWithdraw() internal {
        // Harvest rewards -> Claim CRV and CVX, swap it for USDC
        harvestRewards();

        // Because there is not accurate way to obtain the exact amount of USDC equivalent to the Curve LP tokens,
        // we withdraw and unwrap all Curve LP tokens from Convex. The remaining difference is deposited back in the
        // _afterDepositOrWithdraw() method
        BaseRewardPool(convexRewards).withdrawAllAndUnwrap(false);

        // Get the amount of LP tokens after withdraw form Convex
        uint256 lpTokensToWithdraw = IERC20(curveLpToken).balanceOf(address(this));

        // Approve Deposit Zap contract to move Curve LP tokens
        IERC20(curveLpToken).approve(curveDepositZap, lpTokensToWithdraw);

        // Remove liquidity from Curve and receive the underlying token (USDC)
        I3CrvMetaPoolZap(curveDepositZap).remove_liquidity_one_coin(curveLpToken, lpTokensToWithdraw, 2, 0);
    }

    /**
     * @notice Hook called after a user withdraws USDC from the vault.
     */
    function _afterDepositOrWithdraw() internal {
        // Get remaining USDC in the pool
        uint256 assetsToDeposit = IERC20(usdc).balanceOf(address(this));

        // Approve the Deposit Zap contract to spend USDC
        IERC20(usdc).approve(curveDepositZap, assetsToDeposit);

        // Add the availanle USDC as liquidity to Curve
        I3CrvMetaPoolZap(curveDepositZap).add_liquidity(curveLpToken, [0, 0, assetsToDeposit, 0], 0);

        // Approve Convex Booster contract to move Curve LP tokens
        IERC20(curveLpToken).approve(convexBooster, IERC20(curveLpToken).balanceOf(address(this)));

        // Deposit the Curve LP tokens to Convex Finance
        IConvexBooster(convexBooster).depositAll(convexPoolId, true);
    }

    /**
     * @dev See {ERC4626-_deposit}.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        if (!whitelist[_msgSender()]) revert NotInWhitelist(_msgSender());
        super._deposit(caller, receiver, assets, shares);
        _afterDepositOrWithdraw();
    }

    /**
     * @dev See {ERC4626-_withdraw}.
     */
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        if (!whitelist[_msgSender()]) revert NotInWhitelist(_msgSender());
        _beforeWithdraw();
        super._withdraw(caller, receiver, owner, assets, shares);
        _afterDepositOrWithdraw();
    }
}

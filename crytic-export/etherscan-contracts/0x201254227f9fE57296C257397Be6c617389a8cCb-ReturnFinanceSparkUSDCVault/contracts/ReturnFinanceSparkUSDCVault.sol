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
import {IReturnFinanceSparkUSDCVault} from "./interfaces/IReturnFinanceSparkUSDCVault.sol";

/**
 * @title Return Finance Spark USDC Vault
 * @author 0xFusion (https://0xfusion.com)
 * @dev Return Finance Spark USDC Vault is an ERC4626 compliant vault.
 * @dev The ERC4626 "Tokenized Vault Standard" is defined in https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 */
contract ReturnFinanceSparkUSDCVault is IReturnFinanceSparkUSDCVault, ERC4626, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    /* ========== STATE VARIABLES ========== */

    address public immutable usdc;
    address public immutable dai;
    address public immutable sDai;
    address public immutable uniswapV3Router;

    uint256 public slippage;

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
     * @dev Constructor to initialize the IReturnFinanceSparkV3USDCVault.
     * @param _usdc USDC contract address.
     * @param _dai DAI contract address
     * @param _sDai Spark DAI contract address.
     */
    constructor(IERC20 _usdc, address _dai, address _sDai, address _uniswapV3Router, uint256 _slippage)
        Ownable(_msgSender())
        ERC4626(_usdc)
        ERC20("Return Finance Spark USDC Vault", "rfsUSDC")
    {
        usdc = address(_usdc);
        dai = _dai;
        sDai = _sDai;
        uniswapV3Router = _uniswapV3Router;
        slippage = _slippage;
    }

    /* ========== VIEWS ========== */

    /**
     * @dev See {IERC4626-totalAssets}.
     * We assume USDC to DAI is 1:1
     */
    function totalAssets() public view override returns (uint256) {
        return (IERC4626(sDai).maxWithdraw(address(this)) / 10 ** 12);
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
        uint256 totalDAI = totalAssets();
        IERC4626(sDai).withdraw(totalDAI, destination, address(this));

        emit RescueFunds(totalDAI);
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
     * @notice Set slippage when executing an Uniswap trade
     * @param newSlippage The new slippage configuration
     */
    function setSlippage(uint256 newSlippage) external onlyOwner {
        slippage = newSlippage;

        emit SlippageUpdated(newSlippage);
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
     * @dev Hook called after a user deposits USDC to the vault.
     * @param assets The amount of USDC to be deposited.
     */
    function _afterDeposit(uint256 assets) internal {
        uint256 amountOutMinimum = ((10000 - slippage) * (assets * 10 ** 12)) / 10000;

        IERC20(usdc).approve(uniswapV3Router, assets);
        uint256 daiAmount = _swap(usdc, dai, assets, amountOutMinimum, 100);
        
        IERC20(dai).approve(sDai, daiAmount);
        IERC4626(sDai).deposit(daiAmount, address(this));
    }

    /**
     * @dev Hook called before a user withdraws USDC from the vault.
     * @param assets The amount of USDC to be withdrawn.
     */
    function _beforeWithdraw(uint256 assets) internal returns (uint256 usdcAmount) {
        IERC4626(sDai).withdraw((assets * 10 ** 12), address(this), address(this));

        uint256 amountOutMinimum = ((10000 - slippage) * (assets)) / 10000;
        
        IERC20(dai).approve(uniswapV3Router, assets * 10 ** 12);
        usdcAmount = _swap(dai, usdc, assets * 10 ** 12, amountOutMinimum, 100);
    }

    /**
     * @dev See {ERC4626-_deposit}.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        if (!whitelist[_msgSender()]) revert NotInWhitelist(_msgSender());
        super._deposit(caller, receiver, assets, shares);
        _afterDeposit(assets);
    }

    /**
     * @dev See {ERC4626-_withdraw}.
     */
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        if (!whitelist[_msgSender()]) revert NotInWhitelist(_msgSender());
        uint256 usdcToWithdraw = _beforeWithdraw(assets);
        super._withdraw(caller, receiver, owner, usdcToWithdraw, shares);
    }
}

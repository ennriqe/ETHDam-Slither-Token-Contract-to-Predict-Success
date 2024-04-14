// LINKTREE: https://linktr.ee/liqshare.io
// LANDING: liqshare.io
// X: https://twitter.com/liqshare
// MEDIUM: https://medium.com/@liqshare.io
// TELEGRAM: https://t.me/liqshareio

pragma solidity ^0.8.10;

interface IPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);
}

interface IFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IUniswapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interfaces/IStaking.sol";

contract TAOHarvest is ERC20, Ownable {
    IUniswapRouter public router;
    address public pair;
    address public marketingWallet;
    address public stakingReward;

    bool private swapping;
    bool public tradingEnabled;

    uint256 public swapTokensAtAmount;

    struct Taxes {
        uint256 staking;
        uint256 marketing;
    }

    Taxes public taxes = Taxes(3, 2);

    uint256 public totalTax = 5;

    mapping(address => bool) private _isExcludedFromFees;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    constructor(
        address _marketingWallet,
        address _routerAddress,
        address _stakingReward
    ) ERC20("TAOHarvest Token", "TAH") {
        marketingWallet = _marketingWallet;
        stakingReward = _stakingReward;

        IUniswapRouter _router = IUniswapRouter(_routerAddress);

        address _WETH = _router.WETH();

        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _WETH
        );

        router = _router;
        pair = _pair;
        setSwapTokensAtAmount(400_000);

        excludeFromFees(owner(), true);
        excludeFromFees(_stakingReward, true);
        excludeFromFees(_marketingWallet, true);
        excludeFromFees(address(this), true);

        _mint(owner(), 100_000_000 * (10 ** 18));
    }

    receive() external payable {}

    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount * 10 ** 18;
    }

    function rescueERC20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function forceSend() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        (bool success, ) = payable(marketingWallet).call{value: ETHbalance}("");
        require(success);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function setMarketingWallet(address newWallet) public onlyOwner {
        marketingWallet = newWallet;
    }

    function activateTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (
            !_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping
        ) {
            require(tradingEnabled, "Trading not active");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        address _pair = pair;

        if (
            canSwap &&
            !swapping &&
            to == _pair &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            if (totalTax > 0) {
                swapAndSendReward(swapTokensAtAmount);
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (
            _pair != to && _pair != from
        ) takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            feeAmt = (amount * totalTax) / 100;
            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
        }
        super._transfer(from, to, amount);
    }

    function swapAndSendReward(uint256 tokens) private {
        swapTokensForETH(tokens);
        uint256 currentbalance = address(this).balance;
        if (currentbalance > 0) {
            Taxes memory _taxes = taxes;
            uint256 _totalTax = totalTax;
            uint256 stakingAmt = currentbalance*_taxes.staking / _totalTax;
            uint256 marketingAmt = currentbalance*_taxes.marketing / _totalTax;

            bool success;
            
            (success, ) = payable(stakingReward).call{value: stakingAmt}("");
            require(success, "Failed to send ETH to staking reward");

            (success, ) = payable(marketingWallet).call{value: marketingAmt}("");
            require(success, "Failed to send ETH to marketing wallet");
        }
    }


    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // Make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}
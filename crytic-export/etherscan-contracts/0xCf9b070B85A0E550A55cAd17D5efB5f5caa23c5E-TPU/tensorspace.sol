// SPDX-License-Identifier: MIT

/*
    TensorSpace introduces a token model for creating derivatives of subnet tokens, representing ownership of AI applications on the Bittensor network. 

Website: https://tensorspace.cloud/
X: https://twitter.com/TensorSpace_Ai
Telegram: https://t.me/TensorSpaceAi
Docs: https://tensorspace.gitbook.io/tensorspace-whitepaper/
*/
pragma solidity ^0.8.12;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeMath} from "openzeppelin/utils/math/SafeMath.sol";

import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

contract TPU is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapRouter;
    address public uniswapV2Pair;

    bool private swapping;

    address public tensorMarketingWallet;

    uint256 public maxTensorTxAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxtensorMarketingWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => bool) blacklisted;

    uint256 public buyTotalTensorFees;
    uint256 public buyTPUFee;

    uint256 public sellTotalTensorFees;
    uint256 public sellTPUFee;

    uint256 public tokensForTPU;

    /******************/

    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedmaxTensorTxAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapRouter(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event tensorMarketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    constructor() ERC20("Tensor Space AI", "TPU") {
        IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D 
        );

        excludeFromMaxTransaction(address(_uniswapRouter), true);
        uniswapRouter = _uniswapRouter;

        uint256 _buyTPUFee = 35;
        uint256 _sellTPUFee = 35;

        uint256 totalSupply = 1_000_000_000 * 1e18;

        maxTensorTxAmount = 7_000_000 * 1e18; 
        maxtensorMarketingWallet = 7_000_000 * 1e18; 
        swapTokensAtAmount = (totalSupply * 5) / 10000; 

        buyTPUFee = _buyTPUFee;
        buyTotalTensorFees = buyTPUFee;

        sellTPUFee = _sellTPUFee;
        sellTotalTensorFees = sellTPUFee;

        tensorMarketingWallet = address(0x77fdf5C5e7BF761916086C2E47C26A5db6cA1039);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function setPair() external onlyOwner {
        uniswapV2Pair = IUniswapV2Factory(uniswapRouter.factory())
            .createPair(address(this), uniswapRouter.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapAtTokensAmountTensor(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTensorTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxTensorTxAmount lower than 0.5%"
        );
        maxTensorTxAmount = newNum * (10**18);
    }

    function updatemaxtensorMarketingWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 10) / 1000) / 1e18,
            "Cannot set maxtensorMarketingWallet lower than 1.0%"
        );
        maxtensorMarketingWallet = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedmaxTensorTxAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateBuyFees(
        uint256 _tensorFee
    ) external onlyOwner {
        buyTPUFee = _tensorFee;
        buyTotalTensorFees = buyTPUFee;
    }

    function updateSellFees(
        uint256 _tensorFee
    ) external onlyOwner {
        sellTPUFee = _tensorFee;
        sellTotalTensorFees = sellTPUFee;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updatetensorMarketingWallet(address newWallet) external onlyOwner {
        emit tensorMarketingWalletUpdated(newWallet, tensorMarketingWallet);
        tensorMarketingWallet = newWallet;
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
        require(!blacklisted[from],"Sender blacklisted");
        require(!blacklisted[to],"Receiver blacklisted");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedmaxTensorTxAmount[to]
                ) {
                    require(
                        amount <= maxTensorTxAmount,
                        "Buy transfer amount exceeds the maxTensorTxAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxtensorMarketingWallet,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedmaxTensorTxAmount[from]
                ) {
                    require(
                        amount <= maxTensorTxAmount,
                        "Sell transfer amount exceeds the maxTensorTxAmount."
                    );
                } else if (!_isExcludedmaxTensorTxAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxtensorMarketingWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalTensorFees > 0) {
                fees = amount.mul(sellTotalTensorFees).div(100);
                tokensForTPU += (fees * sellTPUFee) / sellTotalTensorFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalTensorFees > 0) {
                fees = amount.mul(buyTotalTensorFees).div(100);
                tokensForTPU += (fees * buyTPUFee) / buyTotalTensorFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapRouter), tokenAmount);

        // add the liquidity
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForTPU;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }


        uint256 amountToSwapForETH = contractBalance;

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        tokensForTPU = 0;

        (success, ) = address(tensorMarketingWallet).call{value: ethBalance}("");
    }

    function withdrawTensorTokens() external onlyOwner {
        uint256 balance = IERC20(address(this)).balanceOf(address(this));
        IERC20(address(this)).transfer(msg.sender, balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawMainToken(address _token, address _to) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function withdrawETHValue(address toAddr) external onlyOwner {
        (bool success, ) = toAddr.call{
            value: address(this).balance
        } ("");
        require(success);
    }

}
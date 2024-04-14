// SPDX-License-Identifier: MIT
pragma solidity =0.8.17 >=0.8.17 >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import './Helpers.sol';

contract AnonPVP is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public routerCA = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bool private swapping;

    address public treasuryWallet;
    address public teamWallet;
    address public liquidityWallet;
    address public gameWallet;

    uint256 public swapTokensAtAmount;

    mapping(address => bool) public blocked;

    uint256 public buyTotalFees;
    uint256 public buyTreasuryFee;
    uint256 public buyLiquidityFee;
    uint256 public buyTeamFee;
    uint256 public buyGameFee;

    uint256 public sellTotalFees;
    uint256 public sellTreasuryFee;
    uint256 public sellLiquidityFee;
    uint256 public sellTeamFee;
    uint256 public sellGameFee;

    uint256 public tokensForTreasury;
    uint256 public tokensForLiquidity;
    uint256 public tokensForTeam;
    uint256 public tokensForGame;

    mapping(address => bool) private _isExcludedFromFees;

    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event treasuryWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event teamWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event liquidityWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event gameWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("AnonPVP", "PVP") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerCA);

        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _buyTreasuryFee = 18;
        uint256 _buyLiquidityFee = 6;
        uint256 _buyTeamFee = 196;
        uint256 _buyGameFee = 30;

        uint256 _sellTreasuryFee = 18;
        uint256 _sellLiquidityFee = 6;
        uint256 _sellTeamFee = 196;
        uint256 _sellGameFee = 30;

        uint256 totalSupply = 65_000_000 * 1e18;

        swapTokensAtAmount = (totalSupply * 5) / 10000;

        buyTreasuryFee = _buyTreasuryFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyTeamFee = _buyTeamFee;
        buyGameFee = _buyGameFee;
        buyTotalFees = buyTreasuryFee + buyLiquidityFee + buyTeamFee + buyGameFee;

        sellTreasuryFee = _sellTreasuryFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellTeamFee = _sellTeamFee;
        sellGameFee = _sellGameFee;
        sellTotalFees = sellTreasuryFee + sellLiquidityFee + sellTeamFee + sellGameFee;

        treasuryWallet = address(0x7Bac0CA4f267Ebb47A751832A333447c53FB367F);
        teamWallet = address(0xda273697e5971f902872A5E2c64821E452Ba9E7f);
        liquidityWallet = address(0x2F74cd4806237Ff5E27DDbaeDAdb161b496F25Dc);
        gameWallet = address(0x05Ab2310b0B82D92D93832AEeebC043E449AE2F6);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateBuyFees(
        uint256 _treasuryFee,
        uint256 _liquidityFee,
        uint256 _teamFee,
        uint256 _gameFee
    ) external onlyOwner {
        buyTreasuryFee = _treasuryFee;
        buyLiquidityFee = _liquidityFee;
        buyTeamFee = _teamFee;
        buyGameFee = _gameFee;
        buyTotalFees = buyTreasuryFee + buyLiquidityFee + buyTeamFee + buyGameFee;
        require(buyTotalFees <= 250);
    }

    function updateSellFees(
        uint256 _treasuryFee,
        uint256 _liquidityFee,
        uint256 _teamFee,
        uint256 _gameFee
    ) external onlyOwner {
        sellTreasuryFee = _treasuryFee;
        sellLiquidityFee = _liquidityFee;
        sellTeamFee = _teamFee;
        sellGameFee = _gameFee;
        sellTotalFees = sellTreasuryFee + sellLiquidityFee + sellTeamFee + sellGameFee;
        require(sellTotalFees <= 250);
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

    function updateTreasuryWallet(address newTreasuryWallet) external onlyOwner {
        emit treasuryWalletUpdated(newTreasuryWallet, treasuryWallet);
        treasuryWallet = newTreasuryWallet;
    }

    function updateTeamWallet(address newTeamWallet) external onlyOwner {
        emit teamWalletUpdated(newTeamWallet, teamWallet);
        teamWallet = newTeamWallet;
    }

    function updateGameWallet(address newGameWallet) external onlyOwner {
        emit gameWalletUpdated(newGameWallet, gameWallet);
        gameWallet = newGameWallet;
    }

    function updateLiquidityWallet(address newLiquidityWallet) external onlyOwner {
        emit liquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
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
        require(!blocked[from], "Sniper blocked");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(1000);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForTeam += (fees * sellTeamFee) / sellTotalFees;
                tokensForTreasury += (fees * sellTreasuryFee) / sellTotalFees;
                tokensForGame += (fees * sellGameFee) / sellTotalFees;
            }
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(1000);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForTeam += (fees * buyTeamFee) / buyTotalFees;
                tokensForTreasury += (fees * buyTreasuryFee) / buyTotalFees;
                tokensForGame += (fees * buyGameFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function multiBlock(address[] calldata blockees, bool shouldBlock) external onlyOwner {
        for (uint256 i = 0; i < blockees.length; i++) {
            address blockee = blockees[i];
            if (blockee != address(this) &&
            blockee != routerCA &&
                blockee != address(uniswapV2Pair))
                blocked[blockee] = shouldBlock;
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
    }

    function forceSwap() external onlyOwner {
        swapping = true;
        swapBack();
        swapping = false;
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
        tokensForTreasury +
        tokensForTeam +
        tokensForGame;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForTreasury = ethBalance.mul(tokensForTreasury).div(totalTokensToSwap);
        uint256 ethForTeam = ethBalance.mul(tokensForTeam).div(totalTokensToSwap);
        uint256 ethForGame = ethBalance.mul(tokensForGame).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForTreasury - ethForTeam - ethForGame;

        tokensForLiquidity = 0;
        tokensForTreasury = 0;
        tokensForTeam = 0;
        tokensForGame = 0;

        (success,) = address(teamWallet).call{value : ethForTeam}("");
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }
        (success,) = address(gameWallet).call{value : ethForGame}("");
        (success,) = address(treasuryWallet).call{value : address(this).balance}("");
    }
}

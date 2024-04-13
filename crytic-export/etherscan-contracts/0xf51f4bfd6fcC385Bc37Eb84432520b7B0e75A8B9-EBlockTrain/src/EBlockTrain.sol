// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract EBlockTrain is ERC20, Ownable {
    uint16 private constant _maxBuyTax = 25;
    uint16 private constant _maxSellTax = 25;

    bool private _isTrading;
    bool swappingTax;

    uint256 _firstBlock;
    uint16 public _currentBuyTax = 40;
    uint16 public _currentSellTax = 40;
    uint16 public _taxOutThreshold = 950;
    address public _taxAddress;
    uint256 public _maxHolderTokens = 500000 * 10 ** decimals();
    uint256 public _pendingTax;

    mapping (address => bool) private _noFeesOrLimits;

    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2RouterAddr;
    address private _currentPair;

    event taxPaid(address paidTo, uint256 amount);

    constructor()
        ERC20("EeBe Train", "EBTRAIN")
    {
        _uniswapV2RouterAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        _uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddr);

        _noFeesOrLimits[_uniswapV2RouterAddr] = true;
        _noFeesOrLimits[msg.sender] = true;
        _noFeesOrLimits[address(this)] = true;

        _mint(address(this), 1000000 * 10 ** decimals());

        _transferOwnership(msg.sender);
    }

    function setNoFees(address _noFeeAddress) public onlyOwner {
        _noFeesOrLimits[_noFeeAddress] = true;
    }

    function setTaxAddress(address _newTaxAddr) external onlyOwner {
        require(_newTaxAddr != address(0), "TaxAddr: INVALID");
        _taxAddress = _newTaxAddr;
        setNoFees(_taxAddress);
    }

    function updateRouter(address _newRouter) external onlyOwner {
        _uniswapV2RouterAddr = _newRouter;
        setNoFees(_newRouter);
    }

    function setMaxHolderTokens(uint256 newLimit) external onlyOwner {
        require(newLimit <= totalSupply(), "Cannot exceed total supply for max holder limit");
        _maxHolderTokens = newLimit;
    }

    function setTaxes(uint16 _newBuyTax, uint16 _newSellTax) external onlyOwner() {
        require(_newBuyTax <= _maxBuyTax, "BuyTax: TOOHIGH");
        require(_newSellTax <= _maxBuyTax, "SellTax: TOOHIGH");
        _currentBuyTax = _newBuyTax * 10;
        _currentSellTax = _newSellTax * 10;
    }

    function isOverTaxOutThreshold(uint256 amount) public view returns (bool) {
        uint256 pairBalance = balanceOf(_currentPair);
        if (totalSupply() >= pairBalance) {
            uint256 pairBalanceThresholdForTaxTx = totalSupply() - pairBalance;
            return amount < (pairBalanceThresholdForTaxTx * _taxOutThreshold) / 1000;
        }
        return false;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        bool taxAndLimitsEnabled;
        if (!swappingTax && amount > 0 && !_noFeesOrLimits[from] && !_noFeesOrLimits[to]) {
            require(_isTrading, "Not Active");
            taxAndLimitsEnabled = true;
        }
        
        uint256 finalAmount = amount;
        uint256 taxDeducted;
        if (taxAndLimitsEnabled) {
            uint16 buyTax = _currentBuyTax;
            uint16 sellTax = _currentSellTax;
            if (block.number < _firstBlock + 10) {
                buyTax = 250;
                sellTax = 250;
            }
            if (from == _currentPair) {
                taxDeducted = (amount * buyTax) / 1000;
                require(balanceOf(to) + finalAmount <= _maxHolderTokens, "Holder Exceeds Max");
            }
            else if (to == _currentPair) {
                taxDeducted = (amount * sellTax) / 1000;
            }

            finalAmount = amount - taxDeducted;
        }

        if (taxDeducted > 0) {
            super._update(from, address(this), taxDeducted);
            _pendingTax += taxDeducted;
        }

        if (!swappingTax
            && _pendingTax >= 1
            && from != address(_uniswapV2Router)
            && from != _currentPair
            && isOverTaxOutThreshold(_pendingTax)) {

            swappingTax = true;
            _swapTForWE(_pendingTax);
            uint256 ethBalanceCheck = address(this).balance;
            bool successfulPayment = payable(_taxAddress).send(ethBalanceCheck);
            if (successfulPayment) {
                emit taxPaid(_taxAddress, ethBalanceCheck);
            }
            _pendingTax = 0;
            swappingTax = false;
        }
        
        super._update(from, to, finalAmount);
    }

    function _swapTForWE(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function beginTrading(address taxAddr, address[] calldata initWhitelist) external onlyOwner {
        require(!_isTrading, "Already Trading");
        uint256 tokenSupply = totalSupply();
        uint whiteListLength = initWhitelist.length;

        _taxAddress = taxAddr;
        setNoFees(taxAddr);

        for(uint16 i; i < whiteListLength;) {
            setNoFees(initWhitelist[i]);
            unchecked { i++; }
        }

        _approve(address(this), address(_uniswapV2Router), tokenSupply);
        _currentPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _uniswapV2Router.addLiquidityETH{ value: address(this).balance }(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(_currentPair).approve(address(_uniswapV2Router), type(uint256).max);
        _isTrading = true;
        _firstBlock = block.number;
    }

    receive() external payable {}

    function withdraw() external payable onlyOwner {
        (bool successful,) = payable(_taxAddress).call{ value : address(this).balance}(new bytes(0));
        require(successful, "Not Successful");
    }

}

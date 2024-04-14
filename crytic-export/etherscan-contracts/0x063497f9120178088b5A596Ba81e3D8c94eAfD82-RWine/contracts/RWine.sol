// SPDX-License-Identifier: MIT

// https://realwineassets.com
// https://twitter.com/RealWineAssets
// https://t.me/RealWineAssetsOfficialPortal


pragma solidity ^0.8.12;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IMintableNFT {
    function mint(address to) external;
}

contract RWine is Ownable, ERC20 {
    using Address for address payable;
    using SafeMath for uint256;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    uint256 constant NOMINAL_TAX = 5;
    uint256 constant TAX_FACTOR_SWITCH = 33;

    
    IUniswapV2Router02 public router;
    address public router_addr = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public pair;

    bool private swapping = false;
    bool private swapEnabled = false;
    bool public tradingEnabled = false;

    uint256 public supply = 10_000_000 * 10 ** 18;
    uint256 private swapTokensAtAmount = supply * 5 / 1000;
    uint256 public maxTxAmount = supply * 30 / 1000;
    uint256 public maxWalletAmount = supply * 30 / 1000;

    uint256 public totalBuyTax = 0;
    uint256 public totalSellTax = 0;
    uint256 private transactionCount = 0;
    bool public enableUpdateTax = true;
    bool public limitEnabled = true;

    address private treasuryWallet;
    address private vaultWallet;
    
    mapping (address => bool) private _excludedFromFees;
    
    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == treasuryWallet, "Not admin");
        _;
    }
        
    constructor() ERC20("Real Wine Assets", "RWINE") {
        treasuryWallet = address(0x214A7e870531dE8ffF6693E85d2664b03fE8d354); // rwinetreasury.eth
        vaultWallet = address(0x7Ba22B6b691b9a10E1889Db7B8961Ef74288b2f6); // rwinevault.eth
        
        totalBuyTax = 25;
        totalSellTax = 25;
        
        _excludedFromFees[address(this)] = true;
        _excludedFromFees[msg.sender] = true;
        _excludedFromFees[treasuryWallet] = true;
        _excludedFromFees[vaultWallet] = true;
        _excludedFromFees[router_addr] = true;
        _excludedFromFees[DEAD] = true;
        _excludedFromFees[ZERO] = true;
        
        _mint(treasuryWallet, (supply*10)/100);
        _mint(vaultWallet, (supply*60)/100);
        _mint(address(this), (supply*30)/100);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!_excludedFromFees[sender] && !_excludedFromFees[recipient] && !swapping){
            require(tradingEnabled, "Trading not active yet");
            if (limitEnabled) {
                require(amount <= maxTxAmount, "You are exceeding maxTxAmount");
                if(recipient != pair){ 
                    require(balanceOf(recipient) + amount <= maxWalletAmount, "You are exceeding maxWalletAmount");
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;

            if (canSwap && swapEnabled && !swapping && recipient == pair) {
                uint256 amountToSwap = swapTokensAtAmount;
                if (contractTokenBalance >= swapTokensAtAmount * 20) {
                    amountToSwap = swapTokensAtAmount * 20;
                }
                swapForFees(amountToSwap);
            }
        }

        uint256 fee = 0;
        if (!swapping && !_excludedFromFees[sender] && !_excludedFromFees[recipient]) {
            if(recipient == pair) {
                fee = amount * totalSellTax / 100;
            }
            else if (sender == pair) {
                fee = amount * totalBuyTax / 100;
            }
        }

        super._transfer(sender, recipient, amount - fee);
        if(fee > 0) {
            if (enableUpdateTax) {
                updateTaxes();
            }
            super._transfer(sender, address(this) ,fee);
        }

    }

    function swapForFees(uint256 amount) private inSwap {
        swapTokensForETH(amount);
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            uint256 reward = address(this).balance;
            payable(treasuryWallet).sendValue(reward);
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function startTrading() external onlyOwner payable {
        require(!tradingEnabled, "Trading already active");
        router = IUniswapV2Router02(router_addr);
        _approve(address(this), address(router), supply);
        
        pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(pair).approve(address(router), type(uint).max);

        tradingEnabled = true;
        swapEnabled = true;
    }


    function updateTaxes() internal {
        transactionCount += 1;
        if (transactionCount == TAX_FACTOR_SWITCH) {
            totalBuyTax = 15;
            totalSellTax = 15;
        } else if (transactionCount == TAX_FACTOR_SWITCH.mul(2)) {
            totalBuyTax = 10;
            totalSellTax = 10;
        } else if (transactionCount == TAX_FACTOR_SWITCH.mul(3)) {
            totalBuyTax = NOMINAL_TAX;
            totalSellTax = NOMINAL_TAX;
            maxTxAmount = supply * 20 / 1000;
            maxWalletAmount = supply * 20 / 1000;
            enableUpdateTax = false;
        }
    }

    function setTaxToNominal() external onlyOwner {
        totalBuyTax = NOMINAL_TAX;
        totalSellTax = NOMINAL_TAX;
        maxTxAmount = supply * 20 / 1000;
        maxWalletAmount = supply * 20 / 1000;
        enableUpdateTax = false;
    }

    function setSettingsSwap(bool swap) external onlyOwner {
        swapEnabled = swap;
    }

    function removeLimit() external onlyAdmin {
        limitEnabled = false;
    }

    function burnTokensForNFT(uint256 amount, address nftAddr) public onlyAdmin {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        IMintableNFT nftContract = IMintableNFT(nftAddr);
        nftContract.mint(msg.sender);
    }

    receive() external payable {}
}
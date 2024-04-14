/*
███████╗████████╗██╗░░██╗  ███╗░░░███╗░█████╗░███╗░░██╗░██████╗████████╗░█████╗░  ░░░░░░
██╔════╝╚══██╔══╝██║░░██║  ████╗░████║██╔══██╗████╗░██║██╔════╝╚══██╔══╝██╔══██╗  ░░░░░░
█████╗░░░░░██║░░░███████║  ██╔████╔██║██║░░██║██╔██╗██║╚█████╗░░░░██║░░░███████║  █████╗
██╔══╝░░░░░██║░░░██╔══██║  ██║╚██╔╝██║██║░░██║██║╚████║░╚═══██╗░░░██║░░░██╔══██║  ╚════╝
███████╗░░░██║░░░██║░░██║  ██║░╚═╝░██║╚█████╔╝██║░╚███║██████╔╝░░░██║░░░██║░░██║  ░░░░░░
╚══════╝░░░╚═╝░░░╚═╝░░╚═╝  ╚═╝░░░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝  ░░░░░░

████████╗██╗░░██╗███████╗  ██████╗░███████╗░█████╗░░██████╗████████╗  ░█████╗░███████╗
╚══██╔══╝██║░░██║██╔════╝  ██╔══██╗██╔════╝██╔══██╗██╔════╝╚══██╔══╝  ██╔══██╗██╔════╝
░░░██║░░░███████║█████╗░░  ██████╦╝█████╗░░███████║╚█████╗░░░░██║░░░  ██║░░██║█████╗░░
░░░██║░░░██╔══██║██╔══╝░░  ██╔══██╗██╔══╝░░██╔══██║░╚═══██╗░░░██║░░░  ██║░░██║██╔══╝░░
░░░██║░░░██║░░██║███████╗  ██████╦╝███████╗██║░░██║██████╔╝░░░██║░░░  ╚█████╔╝██║░░░░░
░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ╚═════╝░╚══════╝╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░  ░╚════╝░╚═╝░░░░░

███████╗████████╗██╗░░██╗███████╗██████╗░███████╗██╗░░░██╗███╗░░░███╗
██╔════╝╚══██╔══╝██║░░██║██╔════╝██╔══██╗██╔════╝██║░░░██║████╗░████║
█████╗░░░░░██║░░░███████║█████╗░░██████╔╝█████╗░░██║░░░██║██╔████╔██║
██╔══╝░░░░░██║░░░██╔══██║██╔══╝░░██╔══██╗██╔══╝░░██║░░░██║██║╚██╔╝██║
███████╗░░░██║░░░██║░░██║███████╗██║░░██║███████╗╚██████╔╝██║░╚═╝░██║
╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚══════╝░╚═════╝░╚═╝░░░░░╚═╝
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract EthMonsta is
    Initializable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Address for address payable;

    IUniswapV2Router02 private _router; // Uniswap router

    address public feeReceiver; // Address to receive fees
    address public pair; // Address of the token pair on Uniswap
    address private _weth; // Wrapped Ether address

    bool private _inSwapAndLiquify;
    bool public tradingEnabled;

    uint256 public sellTax;

    mapping(address => bool) public isExcludedFromFee;

    error FailedETHSend();
    error InsufficientBalance();
    error InvalidFeeAmount();
    error InvalidTaxAmount(uint256 taxAmount);
    error SamePairAddress();
    error TradingDisabled();
    error ZeroAddress();

    event ExcludedFromFeeUpdated(
        address indexed owner,
        address indexed account,
        bool status
    );
    event TaxesUpdated(address indexed owner, uint256 sellTax, uint256 buyTax);

    modifier LockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier NotZeroAddress(address value) {
        if (value == address(0)) revert ZeroAddress();
        _;
    }

    uint256 public buyTax;

    function initialize(address router, uint256 _sellTax) public initializer {
        __ERC20_init("ETH Monsta", "METH");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _router = IUniswapV2Router02(router);
        _weth = _router.WETH();
        feeReceiver = owner();
        sellTax = _sellTax;

        isExcludedFromFee[address(_router)] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[owner()] = true;

        pair = IUniswapV2Factory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        tradingEnabled = false;

        _mint(_msgSender(), 420000000 * 10 ** decimals());
    }

    receive() external payable {}

    fallback() external payable {}

    function excludeFromFee(
        address _address,
        bool value
    ) external onlyOwner NotZeroAddress(_address) {
        isExcludedFromFee[_address] = value;
        emit ExcludedFromFeeUpdated(_msgSender(), _address, value);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function setFeeReceiver(
        address value
    ) external onlyOwner NotZeroAddress(value) {
        feeReceiver = value;
    }

    function setPair(
        address pairAddress
    ) external onlyOwner NotZeroAddress(pairAddress) nonReentrant {
        if (pairAddress == pair) revert SamePairAddress();
        pair = pairAddress;
    }

    function setTaxes(uint256 _sellTax, uint256 _buyTax) external onlyOwner {
        if (_sellTax > 1000) revert InvalidTaxAmount(_sellTax);
        if (_buyTax > 1000) revert InvalidTaxAmount(_buyTax);
        sellTax = _sellTax;
        buyTax = _buyTax;
        emit TaxesUpdated(_msgSender(), _sellTax, _buyTax);
    }

    function setTradingEnabled(bool value) external onlyOwner {
        tradingEnabled = value;
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawFees() external onlyOwner nonReentrant {
        (bool success, ) = payable(feeReceiver).call{
            value: address(this).balance
        }("");
        if (!success) revert FailedETHSend();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        virtual
        override
        NotZeroAddress(to)
        NotZeroAddress(from)
        whenNotPaused
    {
        if (!tradingEnabled) {
            address owner = owner();
            if (from == owner || to == owner) {
                super._transfer(from, to, amount);
                return;
            } else {
                revert TradingDisabled();
            }
        }
        // sender has sufficient balance
        if (balanceOf(from) < amount) revert InsufficientBalance();

        uint256 tax;
        if (!_inSwapAndLiquify) {
            // sells
            if (to == pair && !isExcludedFromFee[from]) {
                tax = sellTax;
            } else if (from == pair && !isExcludedFromFee[to]) {
                // buys
                tax = buyTax;
            }
        }

        // take taxes
        if (tax > 0) {
            uint256 fee = (amount * tax) / 1e4;
            amount -= fee;
            super._transfer(from, address(this), fee);

            // only swap on sells
            if (to == pair) {
                _swapTokensForEth();
            }
        }

        // transfer balance to recipient
        super._transfer(from, to, amount);
    }

    function _swapTokensForEth() private LockTheSwap {
        uint256 tokenAmount = balanceOf(address(this));
        if (tokenAmount >= 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _router.WETH();

            _approve(address(this), address(_router), tokenAmount);

            _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
    }
}

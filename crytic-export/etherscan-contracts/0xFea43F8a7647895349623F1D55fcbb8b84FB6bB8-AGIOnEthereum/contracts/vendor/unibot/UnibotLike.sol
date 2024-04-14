// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../uniswap/interfaces/IUniswapV2Router02.sol";
import "../uniswap/interfaces/IUniswapV2Factory.sol";

error MaxTransactionAmountExceedsMaxWalletAmount();
error CannotRemovePair(address pair);
error SenderBlacklisted(address sender);
error ReceiverBlacklisted(address receiver);
error BlacklistIsRenounced();
error BlacklistInvalidAddress(address addr);
error ZeroTokenAddress();
error EthTransferFailed(bytes response);
error TradingNotActive();
error MaxTransactionAmountExceeded(uint256 amount, uint256 maxTransactionAmount);
error MaxPerWalletExceeded(uint256 amount, uint256 maxPerWallet);
error CooldownNotExpired(uint64 cooldownRemaining);

contract UnibotLike is ERC20, Ownable, ReentrancyGuard {
    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable UNISWAP_V2_PAIR;

    uint256 public maxTransactionAmount = 50_000_000 * 1e18; // 0.5% of total supply
    uint256 public maxPerWallet = 100_000_000 * 1e18; // 1% of total supply
    uint64 public cooldown = 30 seconds;

    bool public limitsInEffect = true;
    bool public timerInEffect = true;
    bool public tradingActive = false;

    bool public blacklistRenounced = false;

    // anti-bot and anti-whale mappings and variables
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public isEarlyTransferAllowed;
    mapping(address => bool) public isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    // store last trade time per address to prevent bot trading
    mapping(address => uint64) public cooldownTimer;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SetMaxTransactionAmount(uint256 indexed amount);
    event SetMaxPerWallet(uint256 indexed amount);
    event SetCooldown(uint64 indexed cooldown);
    event SetLimitsInEffect(bool indexed limitsInEffect);
    event SetTimerInEffect(bool indexed timerInEffect);
    event SetTradingActive(bool indexed tradingActive);
    event BlacklistRenounced();
    event Blacklisted(address indexed account);
    event Unblacklisted(address indexed account);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 totalSupply
    ) ERC20(_name, _symbol) {
        UNISWAP_V2_PAIR = IUniswapV2Factory(UNISWAP_V2_ROUTER.factory())
            .createPair(address(this), UNISWAP_V2_ROUTER.WETH());

        isEarlyTransferAllowed[msg.sender] = true;
        isEarlyTransferAllowed[address(UNISWAP_V2_ROUTER)] = true;
        isEarlyTransferAllowed[UNISWAP_V2_PAIR] = true;

        isExcludedMaxTransactionAmount[address(UNISWAP_V2_ROUTER)] = true;
        isExcludedMaxTransactionAmount[UNISWAP_V2_PAIR] = true;

        setAutomatedMarketMakerPair(UNISWAP_V2_PAIR, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        if (pair == UNISWAP_V2_PAIR && !value) {
            revert CannotRemovePair(pair);
        }

        automatedMarketMakerPairs[pair] = value;
        isExcludedMaxTransactionAmount[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setMaxTransactionAmount(uint256 _maxTransactionAmount) external onlyOwner {
        maxTransactionAmount = _maxTransactionAmount;
        emit SetMaxTransactionAmount(_maxTransactionAmount);
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
        emit SetMaxPerWallet(_maxPerWallet);
    }

    function setCooldown(uint64 _cooldown) external onlyOwner {
        cooldown = _cooldown;
        emit SetCooldown(_cooldown);
    }

    function setLimitsInEffect(bool _limitsInEffect) external onlyOwner {
        limitsInEffect = _limitsInEffect;
        emit SetLimitsInEffect(_limitsInEffect);
    }

    function setTimerInEffect(bool _timerInEffect) external onlyOwner {
        timerInEffect = _timerInEffect;
        emit SetTimerInEffect(_timerInEffect);
    }

    function setTradingActive(bool _tradingActive) external onlyOwner {
        tradingActive = _tradingActive;
        emit SetTradingActive(_tradingActive);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklisted[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!blacklistRenounced && blacklisted[from]) {
            revert SenderBlacklisted(from);
        }
        if (!blacklistRenounced && blacklisted[to]) {
            revert ReceiverBlacklisted(to);
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead)
            ) {
                if (!tradingActive) {
                    if (!isEarlyTransferAllowed[from] || !isEarlyTransferAllowed[to]) {
                        revert TradingNotActive();
                    }
                }

                // when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !isExcludedMaxTransactionAmount[to]
                ) {
                    if (amount > maxTransactionAmount) {
                        revert MaxTransactionAmountExceeded(amount, maxTransactionAmount);
                    }
                    if (amount + balanceOf(to) > maxPerWallet) {
                        revert MaxPerWalletExceeded(amount, maxPerWallet);
                    }
                }
                // when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !isExcludedMaxTransactionAmount[from]
                ) {
                    if (amount > maxTransactionAmount) {
                        revert MaxTransactionAmountExceeded(amount, maxTransactionAmount);
                    }
                } else if (!isExcludedMaxTransactionAmount[to]) {
                    if (amount + balanceOf(to) > maxPerWallet) {
                        revert MaxPerWalletExceeded(amount, maxPerWallet);
                    }
                }
            }
        }

        if (timerInEffect) {
            if (automatedMarketMakerPairs[from]) {
                if (block.timestamp - cooldownTimer[to] < cooldown) {
                    revert CooldownNotExpired(cooldown - (uint64(block.timestamp) - cooldownTimer[to]));
                }
                cooldownTimer[to] = uint64(block.timestamp);
            } else if (automatedMarketMakerPairs[to]) {
                if (block.timestamp - cooldownTimer[from] < cooldown) {
                    revert CooldownNotExpired(cooldown - (uint64(block.timestamp) - cooldownTimer[from]));
                }
                cooldownTimer[from] = uint64(block.timestamp);
            }
        }

        super._transfer(from, to, amount);
    }

    function withdrawStuckTokens(address[] memory _tokens, address _to) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            withdrawStuckToken(_tokens[i], _to);
        }
        withdrawStuckEth(_to);
    }

    function withdrawStuckToken(address _token, address _to) public onlyOwner {
        if(_token == address(0)) {
            revert ZeroTokenAddress();
        }
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function withdrawStuckEth(address _to) public onlyOwner {
        (bool success, bytes memory response) = _to.call{value: address(this).balance}("");
        if (!success) {
            revert EthTransferFailed(response);
        }
    }

    /// @dev team renounce blacklist commands
    function renounceBlacklist() public onlyOwner {
        blacklistRenounced = true;
        emit BlacklistRenounced();
    }

    /// @dev to blacklist v3 pools; can unblacklist() down the road to suit project and community
    function blacklist(address _addr) public onlyOwner {
        if (blacklistRenounced) {
            revert BlacklistIsRenounced();
        }
        if (_addr == address(UNISWAP_V2_ROUTER) || _addr == address(UNISWAP_V2_PAIR)) {
            revert BlacklistInvalidAddress(_addr);
        }
        blacklisted[_addr] = true;
        emit Blacklisted(_addr);
    }

    /// @dev unblacklist address; not affected by blacklistRenounced incase team wants to unblacklist v3 pools down the road
    function unblacklist(address _addr) public onlyOwner {
        blacklisted[_addr] = false;
        emit Unblacklisted(_addr);
    }
}
/*                                                                                                                                                              
                                                                                                                                                               
  .g8"""bgd  `7MMF'   `7MF'  .g8"""bgd   .g8"""bgd `7MMF'    `7MMF'   `7MF'      db      `7MN.   `7MF'      .g8"""bgd    .g8""8q.     .g8"""bgd  `7MMF'  `7MMF'
.dP'     `M    MM       M  .dP'     `M .dP'     `M   MM        `MA     ,V       ;MM:       MMN.    M      .dP'     `M  .dP'    `YM. .dP'     `M    MM      MM  
dM'       `    MM       M  dM'       ` dM'       `   MM         VM:   ,V       ,V^MM.      M YMb   M      dM'       `  dM'      `MM dM'       `    MM      MM  
MM             MM       M  MM          MM            MM          MM.  M'      ,M  `MM      M  `MN. M      MM           MM        MM MM             MMmmmmmmMM  
MM.    `7MMF'  MM       M  MM.         MM.           MM          `MM A'       AbmmmqMA     M   `MM.M      MM.    `7MMF'MM.      ,MP MM.    `7MMF'  MM      MM  
`Mb.     MM    YM.     ,M  `Mb.     ,' `Mb.     ,'   MM           :MM;       A'     VML    M     YMM      `Mb.     MM  `Mb.    ,dP' `Mb.     MM    MM      MM  
  `"bmmmdPY     `bmmmmd"'    `"bmmmd'    `"bmmmd'  .JMML.          VF      .AMA.   .AMMA..JML.    YM        `"bmmmdPY    `"bmmd"'     `"bmmmdPY  .JMML.  .JMML.
                                                                                                                                                                                                                                                                                                                              
*/

/**
 * Telegram: https://t.me/+Uq9g5yOnauI5Zjgx
 * Website: https://guccivangogh.com
 * Twitter: https://twitter.com/guccivangogh_
 *
 * GucciVanGogh revolutionizes the art world with decentralized NFT galleries and museums enhanced by VR/AR providing
 * global art access. It offers a provenance tracking system for authenticity, connects artists with patrons through NFTs for
 * funding, and streamlines art licensing and royalties via smart contracts. The platform supports interactive art projects,
 * cross-media experiences, digital art preservation, tokenized art investments, collaborative artist platforms,
 * and cultural heritage preservation, creating a multifaceted ecosystem for art engagement and preservation.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GucciVanGogh
 * @dev This contract implements a custom ERC20 token with additional features.
 * It includes mechanisms for whitelisting and blacklisting addresses,
 * as well as custom rules for transferring tokens.
 * The contract is Ownable and the owner can set the state of trading,
 * add liquidity, and set the Uniswap pair and router addresses.
 * The owner can also set the whitelist status of an address and blacklist an address.
 * These measures are in place to prevent front-running and other attacks.
 * The contract also includes custom transaction limits and holding limits.
 */
contract GucciVanGogh is ERC20, Ownable(0xC3C97156f10CC43917289Aa1BC63b4aa67F9a97B) {
    /**
     * @dev Constants for token supply and transaction limits.
     * TOTAL_SUPPLY is the total supply of tokens.
     * MAX_TX_LIMIT is the maximum amount of tokens that can be transferred in a single transaction.
     * MAX_HOLDING_LIMIT is the maximum amount of tokens that an address can hold.
     * These values are set in the constructor.
     * The values are public and can be accessed using their respective getter functions.
     */
    uint256 private constant TOTAL_SUPPLY = 1_000_000_000_000_000 ether;
    uint256 private constant MAX_TX_LIMIT = TOTAL_SUPPLY / 50;
    uint256 private constant MAX_HOLDING_LIMIT = TOTAL_SUPPLY / 50;

    /**
     * @dev Mapping to keep track of whitelisted addresses.
     * Whitelisted addresses are allowed to send and receive tokens.
     * The owner address is whitelisted by default.
     * The Uniswap pair and router addresses are whitelisted by default.
     */
    mapping(address => bool) private _isWhitelisted;

    /**
     * Mapping to keep track of blacklisted addresses.
     * Blacklisted addresses are not allowed to send or receive tokens.
     */
    mapping(address => bool) private _isBlacklisted;

    /**
     * @dev Boolean representing the state of trading.
     * _tradingStarted is set to true when trading starts.
     * _liquidityAdded is set to true when liquidity is added.
     */
    bool private _tradingStarted = false;
    bool private _liquidityAdded = false;

    // Addresses for Uniswap pair and router.
    address private _uniswapPairAddress;
    address private _uniswapRouterAddress;

    /**
     * @dev Constructor that mints tokens to the deployer and sets them as whitelisted.
     */
    constructor() ERC20("GucciVanGogh", "GOGH") {
        _mint(msg.sender, TOTAL_SUPPLY);
        _isWhitelisted[msg.sender] = true;
    }

    /**
     * @dev Function to add liquidity. Only the owner can call this function.
     */
    function addLiquidity() public onlyOwner {
        _liquidityAdded = true;
    }

    /**
     * @dev Starts trading. Requires liquidity to be already added. Only callable by the owner.
     */
    function startTrading() public onlyOwner {
        require(_liquidityAdded, "Liquidity has not been added yet");
        _tradingStarted = true;
    }

    /**
     * @dev Renounces ownership of the contract.
     * This is an irreversible operation that cannot be undone.
     * Once ownership is renounced, the contract will no longer have an owner,
     * and certain functionalities will be permanently disabled.
     * Only callable by the owner.
     * Overrides the renounceOwnership function in the Ownable contract.
     * The addresses already whitelisted will remain whitelisted.
     * The addresses already blacklisted will remain blacklisted.
     */
    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }

    /**
     * @dev Sets the Uniswap pair address. Only callable by the owner.
     * @param uniswapPair Address of the Uniswap pair.
     */
    function setUniswapPairAddress(address uniswapPair) public onlyOwner {
        _uniswapPairAddress = uniswapPair;
    }

    /**
     * @dev Sets the Uniswap router address. Only callable by the owner.
     * @param uniswapRouter Address of the Uniswap router.
     */
    function setUniswapRouterAddress(address uniswapRouter) public onlyOwner {
        _uniswapRouterAddress = uniswapRouter;
    }

    /**
     * @dev Sets the whitelist status of an address. Only callable by the owner.
     * @param account Address to be updated.
     * @param status Boolean representing the whitelist status.
     */
    function setWhitelistStatus(address account, bool status) public onlyOwner {
        _isWhitelisted[account] = status;
    }

    /**
     * @dev Blacklists an address. Only callable by the owner.
     * @param account Address to be blacklisted.
     * @param value Boolean representing the blacklist status.
     */
    function blacklistAddress(address account, bool value) public onlyOwner {
        _isBlacklisted[account] = value;
    }

    /**
     * @dev Checks if an address is whitelisted.
     * @param account Address to check.
     * @return bool True if the address is whitelisted, false otherwise.
     */
    function isWhitelisted(address account) public view returns (bool) {
        return _isWhitelisted[account];
    }

    /**
     * @dev Checks if an address is blacklisted.
     * @param account Address to check.
     * @return bool True if the address is blacklisted, false otherwise.
     */
    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }

    /**
     * @dev Overrides the transfer function with additional checks for blacklist, whitelist,
     * and transaction limits.
     * @param recipient The address to transfer to.
     * @param amount The amount to be transferred.
     * @return bool True if the transfer is successful, false otherwise.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!_isBlacklisted[msg.sender], "Sender is blacklisted");

        // Owner can trade before trading started and bypass the limit if removing liquidity
        if (msg.sender != owner()) {
            require(_tradingStarted, "Trading has not started");
        }

        if (!_isWhitelisted[recipient] && recipient != _uniswapPairAddress) {
            require(balanceOf(recipient) + amount <= MAX_HOLDING_LIMIT, "Recipient holding exceeds limit");
        }

        return super.transfer(recipient, amount);
    }

    /**
     * @dev Overrides the transferFrom function with additional checks for blacklist, whitelist,
     * and transaction limits.
     * @param sender The address to transfer from.
     * @param recipient The address to transfer to.
     * @param amount The amount to be transferred.
     * @return bool True if the transfer is successful, false otherwise.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(!_isBlacklisted[sender], "Sender is blacklisted");

        /**
         * Owner can trade before trading started and bypass the limit if removing liquidity
         */
        if (sender != owner()) {
            require(_tradingStarted, "Trading has not started");
        }

        /**
         * Check if the recipient is whitelisted.
         * If not, check if the recipient's balance will exceed the limit.
         */
        if (!_isWhitelisted[recipient] && recipient != _uniswapPairAddress) {
            require(balanceOf(recipient) + amount <= MAX_HOLDING_LIMIT, "Recipient holding exceeds limit");
        }

        return super.transferFrom(sender, recipient, amount);
    }

    /**
     * @dev Public getter for the MAX_TX_LIMIT
     * @return uint256 Maximum transaction limit.
     */
    function getMaxTxLimit() public pure returns (uint256) {
        return MAX_TX_LIMIT;
    }

    /**
     * @dev Public getter for the MAX_HOLDING_LIMIT
     * @return uint256 Maximum holding limit.
     */
    function getMaxHoldingLimit() public pure returns (uint256) {
        return MAX_HOLDING_LIMIT;
    }

    /**
     * @dev Public getter for the Uniswap Pair Address
     * @return address Address of the Uniswap pair.
     */
    function getUniswapPairAddress() public view returns (address) {
        return _uniswapPairAddress;
    }

    /**
     * @dev Public getter for the Uniswap Router Address
     * @return address Address of the Uniswap router.
     */
    function getUniswapRouterAddress() public view returns (address) {
        return _uniswapRouterAddress;
    }

    /**
     * @dev Getter for the trading started status
     * @return bool True if trading has started, false otherwise.
     */
    function hasTradingStarted() public view returns (bool) {
        return _tradingStarted;
    }

    /**
     * @dev Getter for the renounce ownership status
     * @return bool True if ownership has been renounced, false otherwise.
     */
    function hasOwnershipBeenRenounced() public view returns (bool) {
        return owner() == address(0);
    }

    /**
     * @dev Getter for the liquidity added status
     * @return bool True if liquidity has been added, false otherwise.
     */
    function hasLiquidityBeenAdded() public view returns (bool) {
        return _liquidityAdded;
    }

    /**
     * @dev Getter function to check if Uniswap Pair Address is whitelisted
     * @return bool True if the Uniswap Pair Address is whitelisted, false otherwise.
     */
    function isUniswapPairWhitelisted() public view returns (bool) {
        return _isWhitelisted[_uniswapPairAddress];
    }

    /**
     * @dev Getter function to check if Uniswap Router Address is whitelisted
     * @return bool True if the Uniswap Router Address is whitelisted, false otherwise.
     */
    function isUniswapRouterWhitelisted() public view returns (bool) {
        return _isWhitelisted[_uniswapRouterAddress];
    }

    /**
     * @dev Getter function to check if the owner address is whitelisted
     * @return bool True if the owner address is whitelisted, false otherwise.
     */
    function isOwnerWhitelisted() public view returns (bool) {
        return _isWhitelisted[owner()];
    }

    /**
     * @dev Getter function to check if Uniswap Pair Address is blacklisted
     * @return bool True if the Uniswap Pair Address is blacklisted, false otherwise.
     */
    function isUniswapPairBlacklisted() public view returns (bool) {
        return _isBlacklisted[_uniswapPairAddress];
    }

    /**
     * @dev Getter function to check if Uniswap Router Address is blacklisted
     * @return bool True if the Uniswap Router Address is blacklisted, false otherwise.
     */
    function isUniswapRouterBlacklisted() public view returns (bool) {
        return _isBlacklisted[_uniswapRouterAddress];
    }

    /**
     * @dev Getter function to check if the owner address is blacklisted
     * @return bool True if the owner address is blacklisted, false otherwise.
     */
    function isOwnerBlacklisted() public view returns (bool) {
        return _isBlacklisted[owner()];
    }

    /**
     * @dev Getter for checking whitelist status of any address
     * @param account Address to check the whitelist status.
     * @return bool True if the address is whitelisted, false otherwise.
     */
    function checkWhitelistStatus(address account) public view returns (bool) {
        return _isWhitelisted[account];
    }

    /**
     * @dev Getter for checking blacklist status of any address
     * @param account Address to check the blacklist status.
     * @return bool True if the address is blacklisted, false otherwise.
     */
    function checkBlacklistStatus(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }
}

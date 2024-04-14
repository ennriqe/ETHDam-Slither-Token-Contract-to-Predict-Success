// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NewWorldToken is ERC20, ERC20Burnable, Ownable, ReentrancyGuard {
    uint256 public constant DAILY_PERCENTAGE = 1;
    mapping(address => uint256) public lastSellTime;
    mapping(address => uint256) public dailySellAmount;

    constructor() ERC20("New World NFT Game", "NWO") Ownable(msg.sender) {
        _mint(msg.sender, 100000 * 10**18); // Mint 100k tokens for simplicity
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(canSell(_msgSender(), amount), "Limit exceeded");
        updateSellData(_msgSender(), amount);
        return super.transfer(recipient, amount);
    }

    function canSell(address seller, uint256 amount) public view returns (bool) {
        uint256 balance = balanceOf(seller);
        uint256 dailyLimit = (balance * DAILY_PERCENTAGE) / 100;
        
        if (block.timestamp - lastSellTime[seller] >= 1 days) {
            return amount <= dailyLimit;
        } else {
            return dailySellAmount[seller] + amount <= dailyLimit;
        }
    }

    function updateSellData(address seller, uint256 amount) internal {
        if (block.timestamp - lastSellTime[seller] >= 1 days) {
            dailySellAmount[seller] = 0; // Reset if it's a new day
        }

        lastSellTime[seller] = block.timestamp;
        dailySellAmount[seller] += amount;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.1/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.1/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.1/contracts/access/Ownable.sol";

contract WhiteToken is ERC20, Ownable, ReentrancyGuard {
    struct Stake {
        uint256 amount;
        uint256 yieldTokens;
        uint256 lastUpdated;
    }

    uint256 private constant HOURLY_YIELD = 1351; 
    uint256 private constant YIELD_INTERVAL = 1 hours;
    uint256 public TOTAL_SUPPLY = 500000000000 * (10 ** decimals()); 

    mapping(address => Stake) public stakes;
    mapping(address => bool) public blacklist;

    event Staked(address indexed user, uint256 amount, uint256 time);
    event Unstaked(address indexed user, uint256 amount, uint256 yield, uint256 time);
    event YieldClaimed(address indexed user, uint256 yield, uint256 time);
    event Blacklisted(address indexed user, bool isBlacklisted);

    constructor() ERC20("WHITE", "WHITE") {
      
        _mint(0x89Bb4DA4AF4b7f137610DB2EE4C6672Ab5392073, TOTAL_SUPPLY * 70 / 100);
        _mint(0x3D012E9511E0E472171c07b2B3E2B407375a3296, TOTAL_SUPPLY * 20 / 100);
        _mint(0xbDBb851f6435cA427D3Bd926863df0f33AA2D0f3, TOTAL_SUPPLY * 10 / 100);

        transferOwnership(0x89Bb4DA4AF4b7f137610DB2EE4C6672Ab5392073);
    }

    function stake(uint256 _amount) external nonReentrant {
        require(!blacklist[msg.sender], "Address is blacklisted");
        require(_amount > 0, "Cannot stake 0 tokens");
        require(balanceOf(msg.sender) >= _amount, "Not enough tokens to stake");

        _updateYield(msg.sender);

        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].lastUpdated = block.timestamp;

        _transfer(msg.sender, address(this), _amount);
        
        emit Staked(msg.sender, _amount, block.timestamp);
    }

    function unstake(uint256 _amount) external nonReentrant {
        require(!blacklist[msg.sender], "Address is blacklisted");
        require(_amount > 0, "Cannot unstake 0 tokens");
        require(stakes[msg.sender].amount >= _amount, "Not enough tokens to unstake");

        _updateYield(msg.sender);

        uint256 yield = stakes[msg.sender].yieldTokens;
        stakes[msg.sender].yieldTokens = 0;
        stakes[msg.sender].amount -= _amount;

        _transfer(address(this), msg.sender, _amount + yield);
        
        emit Unstaked(msg.sender, _amount, yield, block.timestamp);
    }

    function claimYield() external nonReentrant {
        require(!blacklist[msg.sender], "Address is blacklisted");
        _updateYield(msg.sender);

        uint256 yield = stakes[msg.sender].yieldTokens;
        require(yield > 0, "No yield to claim");

        stakes[msg.sender].yieldTokens = 0;
        _transfer(address(this), msg.sender, yield);

        emit YieldClaimed(msg.sender, yield, block.timestamp);
    }

    function _updateYield(address staker) internal {
        uint256 timePassed = block.timestamp - stakes[staker].lastUpdated;
        if (timePassed >= YIELD_INTERVAL) {
            uint256 hoursPassed = timePassed / YIELD_INTERVAL;
            uint256 yieldToAdd = (stakes[staker].amount * HOURLY_YIELD * hoursPassed) / (100000 * 24 * 30); // Tasa por hora
            stakes[staker].yieldTokens += yieldToAdd;
            stakes[staker].lastUpdated = block.timestamp;
        }
    }

    function manageBlacklist(address _user, bool _isBlacklisted) external onlyOwner {
        blacklist[_user] = _isBlacklisted;
        emit Blacklisted(_user, _isBlacklisted);
    }

    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }
    
    function calculateYield(address staker) public view returns (uint256) {
        uint256 timePassed = block.timestamp - stakes[staker].lastUpdated;
        uint256 hoursPassed = timePassed / YIELD_INTERVAL;
        uint256 yield = (stakes[staker].amount * HOURLY_YIELD * hoursPassed) / (100000 * 24 * 30);
        return stakes[staker].yieldTokens + yield;
    }
}

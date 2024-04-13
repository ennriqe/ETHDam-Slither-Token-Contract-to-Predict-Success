// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPRTLToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract PremiumReserve {
    address private owner;
    uint8 public decimals;
    uint256 public premiumPrice;
    uint256 public premiumPriceERC;
    uint32 private totalReserved;
    uint32 public uniqueUsers;
    
    uint32 private constant MAX_RESERVES = 500;
    bool public reserveOn;
    mapping(address => uint32) internal reserved;
    IPRTLToken private prtlToken;

    event Transfer(address indexed from, address indexed to, uint256 value);

    modifier ownerOnly() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor(uint256 price,uint256 priceerc, address prtlTokenAddress) {
        owner = msg.sender;
        premiumPrice = price;
        premiumPriceERC = priceerc;
        prtlToken = IPRTLToken(prtlTokenAddress);
        decimals = 0;
    }

    function start() public ownerOnly {
        reserveOn = true;
    }

    function end() public ownerOnly {
        reserveOn = false;
    }

    function reserveApexETH(uint32 amount) public payable {
        require(reserveOn, "Reserve has not started yet.");
        require(totalReserved + amount <= MAX_RESERVES, "Max reserves reached");
        require(msg.value == (premiumPrice * amount), "Incorrect value");
        require(reserved[msg.sender] + amount <= 3, "Max reserves per User reached");

        if (reserved[msg.sender] == 0) {
            uniqueUsers += 1;
        }

        reserved[msg.sender] += amount;
        totalReserved += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function reserveApexPRTL(uint32 amount) public {
        require(reserveOn, "Reserve has not started yet.");
        require(totalReserved + amount <= MAX_RESERVES, "Max reserves reached");
        uint256 requiredTokens = premiumPriceERC * amount;
        require(prtlToken.transferFrom(msg.sender, owner, requiredTokens), "Token transfer failed");
        require(reserved[msg.sender] + amount <= 3, "Max reserves per User reached");
        
        if (reserved[msg.sender] == 0) {
            uniqueUsers += 1;
        }

        reserved[msg.sender] += amount;
        totalReserved += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function updatePrice(uint256 newPrice) public ownerOnly{
        premiumPriceERC = newPrice;
        
    }


    function name() public pure returns (string memory) {
        return "Apex Reserve";
    }

    function symbol() public pure returns (string memory) {
        return "AR";
    }

    

    function balanceOf(address user) public view returns (uint32) {
        return reserved[user];
    }

    function getTotalReserved() public view returns (uint32) {
        return totalReserved;
    }

    function withdraw() public ownerOnly {
        uint256 totalBalance = address(this).balance;
        require(totalBalance > 0, "No funds to withdraw");

        (bool sent, ) = owner.call{value: totalBalance}("");
        require(sent, "Failed to send Ether");
    }
}
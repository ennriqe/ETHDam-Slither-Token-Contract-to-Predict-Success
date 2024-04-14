// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8 .20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AiNex is ERC20, ERC20Burnable, Ownable {
    address public feeToken;
    uint256 public transferFeePercentage = 10;
    uint256 public transferFeePercentageafter24hrs = 5;
    uint256 public buyfee = 3;
    uint256 timestamp;
    address public feeWallet = 0x829dc004Ed91833Dd5A62b788eD61551F0B051D2;
    mapping(address => bool) public whitelistedAddress;
    bool public stopwhitelisting;

    constructor() 
        ERC20("Neural Nexus AI", "AiNex") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }



    function WhiteList(address[] memory UserAddresses) external onlyOwner returns(bool) {
        for (uint i = 0; i < UserAddresses.length; i++) {
            whitelistedAddress[UserAddresses[i]] = true;
        }
        return true;
    }

    function RemoveWhiteList(address[] memory UserAddresses) external onlyOwner returns(bool) { //** this function will blacklist the address and User Can't be able to use transfer and transferFrom Function **
        for (uint i = 0; i < UserAddresses.length; i++) {
            whitelistedAddress[UserAddresses[i]] = false;
        }
        return true;
    }

    function stopWhitelisting(bool stop) external onlyOwner returns(bool) {
        stopwhitelisting = stop;
        return true;
    }

    function changeBuyfee(uint Percentage) external onlyOwner returns(bool) {
        buyfee = Percentage;
        return true;
    }

    function changeSellfee(uint Percentage) external onlyOwner returns(bool) {
        transferFeePercentage = Percentage;
        return true;
    }

    function changesellfeeafter24hrs(uint Percentage) external onlyOwner returns(bool) {
        transferFeePercentageafter24hrs = Percentage;
        return true;
    }


    function updatetokenaddress(address _tokenaddress) external onlyOwner {
        feeToken = _tokenaddress;
        timestamp = block.timestamp;
    }


    function transfer(
        address to,
        uint256 amount
    ) public override returns(bool) {
        uint256 fee = 0;
        if (msg.sender == feeToken) {
            if (stopwhitelisting == true || whitelistedAddress[to] == false) {
                fee = amount * buyfee / 100;
            }

        }
        uint256 amountAfterFee = amount - fee;

        _transfer(msg.sender, to, amountAfterFee);
        if (fee > 0) {
            _transfer(msg.sender, feeWallet, fee); // Transfer fee to owner
        }

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns(bool) {
        uint256 fee = 0;
        if (to == feeToken) {
            if (stopwhitelisting == true || whitelistedAddress[from] == false) {
                if (timestamp + 20 minutes >= block.timestamp) {
                    fee = amount * transferFeePercentage / 100;
                } else {
                    fee = amount * transferFeePercentageafter24hrs / 100;
                }
            }


        }
        uint256 amountAfterFee = amount - fee;

        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amountAfterFee);
        if (fee > 0) {
            _transfer(from, feeWallet, fee); // Transfer fee to owner
        }

        return true;
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ThePrimaryParty is ERC20, Ownable {
    // Tax percentage in basis points (1 basis point = 0.01%)
    uint256 public taxPercentage;
    address public taxWallet;

    event TaxPercentageSet(uint256 taxPercentage);
    event TaxWalletSet(address taxWallet);

    constructor(
        uint256 initialSupply,
        address _initialTaxWallet,
        address _republicanWallet,
        address _teamWallet,
        address _marketingWallet
    ) ERC20("The Primary Party", "POTUS") Ownable(msg.sender) {
        // Deployer Supply = 50%
        uint256 deployerSupply = initialSupply / 2;
        _mint(msg.sender, deployerSupply);

        // Republican Supply = 30%
        uint256 republicanSupply = initialSupply * 3 / 10;
        _mint(_republicanWallet, republicanSupply);

        // Team Supply = 15%
        uint256 teamSupply = initialSupply * 3 / 20;
        _mint(_teamWallet, teamSupply);

        // Marketing Supply = 5%
        uint256 marketingSupply = initialSupply / 20;
        _mint(_marketingWallet, marketingSupply);

        taxWallet = _initialTaxWallet;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 taxAmount = (amount * taxPercentage) / 10000;
        uint256 transferAmount = amount - taxAmount;

        super.transfer(recipient, transferAmount);
        if (taxAmount > 0) {
            super.transfer(owner(), taxAmount);
        }

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 taxAmount = (amount * taxPercentage) / 10000;
        uint256 transferAmount = amount - taxAmount;

        super.transferFrom(from, to, transferAmount);
        if (taxAmount > 0) {
            super.transferFrom(from, taxWallet, taxAmount);
        }

        return true;
    }

    function setTaxPercentage(uint256 _taxPercentage) public onlyOwner {
        require(taxPercentage <= 10000, "Tax percentage can't exceed 100%");
        taxPercentage = _taxPercentage;
        emit TaxPercentageSet(_taxPercentage);
    }

    function setTaxWallet(address _taxWallet) external onlyOwner {
        require(
            _taxWallet != address(0),
            "Tax wallet cannot be the zero address"
        );
        taxWallet = _taxWallet;
        emit TaxWalletSet(_taxWallet);
    }
}

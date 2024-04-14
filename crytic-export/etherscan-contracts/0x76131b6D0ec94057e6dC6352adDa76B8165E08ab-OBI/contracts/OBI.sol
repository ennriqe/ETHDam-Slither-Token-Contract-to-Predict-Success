// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OBI is ERC20, ERC20Burnable, Ownable {
    // Mapping to store minimum balances for certain accounts
    mapping(address => uint256) public _minimumBalances;

    // Store the timestamp six months after the contract's deployment
    uint256 public _sixMonthsAfterDeployment;

    // Once set to true, the aidrop function is disabled
    bool public fuse;

    constructor() ERC20("Obi Real Estate", "OBICOIN") Ownable(msg.sender) {
        // Set the deployment time to the current block timestamp
        _sixMonthsAfterDeployment = block.timestamp + 180 days;

        _mint(0x0ADaC15aa5b466349f31392276F1E6C3dc151C4d, 32000000 ether); // Founder 1
        _mint(0x04e7FfF294c99065dDaFe1Fc27ACd001e9a380b7, 48000000 ether); // Founder 2
        _mint(0x33b6AEb21BBA91F35Ef5A9A54668fff54131ee63, 863180902 ether); // Treasury
    }

    // Override the transfer function
    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        // Check if six months have passed since deployment
        if (block.timestamp < _sixMonthsAfterDeployment) {
            // Check if the sender's balance will go below the minimum balance
            require(
                balanceOf(msg.sender) - value >= _minimumBalances[msg.sender],
                "transfer: transfer amount exceeds minimum balance"
            );
        }

        // If the checks pass, proceed with the transfer
        return super.transfer(to, value);
    }

    // Override the transferFrom function
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        // Check if six months have passed since deployment
        if (block.timestamp < _sixMonthsAfterDeployment) {
            // Check if the sender's balance will go below the minimum balance
            require(
                balanceOf(from) - value >= _minimumBalances[from],
                "transferFrom: transfer amount exceeds minimum balance"
            );
        }

        // If the checks pass, proceed with the transfer
        return super.transferFrom(from, to, value);
    }

    function airdrop(
        address[] calldata _to,
        uint256[] calldata _amount
    ) public onlyOwner {
        if (fuse) {
            revert("airdrop: fuse has been blown");
        }

        // Check if the arrays are not the same length
        if (_to.length != _amount.length) {
            revert("airdrop: _to and _amount arrays must have the same length");
        }

        uint256 i;

        for (; i < _to.length; ) {
            _minimumBalances[_to[i]] = _amount[i];
            _mint(_to[i], _amount[i]);
            unchecked {
                ++i;
            }
        }
    }

    function blowFuse() public onlyOwner {
        fuse = true;
    }
}

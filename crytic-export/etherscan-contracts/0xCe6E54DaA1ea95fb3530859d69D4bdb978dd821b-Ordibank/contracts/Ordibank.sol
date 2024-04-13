// SPDX-License-Identifier: GPL-3.0-or-later

// Ordibank
// Project Details: https://linktr.ee/Ordibank

pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Ordibank is ERC20, Ownable2Step {
    address public constant DEAD_ADDRESS = address(0xdead);

    bool public launched;
    mapping(address => bool) public isExcludedFromLimits;

    event Launch();
    event ExcludeFromLimits(address indexed account, bool value);

    constructor() ERC20("Ordibank", "ORBK") Ownable(msg.sender) {
        _excludeFromLimits(_msgSender(), true);
        _excludeFromLimits(address(this), true);
        _excludeFromLimits(DEAD_ADDRESS, true);
        _excludeFromLimits(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6, true);
        _excludeFromLimits(0x61fFE014bA17989E743c5F6cB21bF9697530B21e, true);

        _mint(_msgSender(), 1_000_000_000 ether);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function launch() public onlyOwner {
        require(!launched, "Ordibank: Already launched.");
        launched = true;
        emit Launch();
    }

    function excludeFromLimits(address[] calldata accounts, bool value) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _excludeFromLimits(accounts[i], value);
        }
    }

    function _update(address from, address to, uint256 amount) internal virtual override {
        if (launched || isExcludedFromLimits[from] || isExcludedFromLimits[to]) {
            super._update(from, to, amount);
            return;
        }

        require(
            from == owner() || to == owner() || to == DEAD_ADDRESS || tx.origin == owner(),
            "Ordibank: Not launched."
        );

        super._update(from, to, amount);
    }

    function _excludeFromLimits(address account, bool value) internal virtual {
        isExcludedFromLimits[account] = value;
        emit ExcludeFromLimits(account, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

contract IQ50 is ERC20Pausable, Ownable {

    uint256 private constant MAX_SUPPLY = 505050505050 * 1E18;

    mapping(address => bool) public whitelist;

    constructor(address account) ERC20('IQ50', 'IQ50') {
        _mint(account, MAX_SUPPLY);
        _pause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (!whitelist[from]) super._beforeTokenTransfer(from, to, amount);
    }

    function setWhitelist(address account, bool isAdd) public onlyOwner {
        if (whitelist[account] != isAdd) {
            whitelist[account] = isAdd;
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/AntiWhaleToken.sol";
import "../libraries/ERC20Base.sol";

/**
 * @dev ERC20Token implementation with AntiWhale capabilities
 */
contract PXPToken is ERC20Base, AntiWhaleToken, Ownable {
    mapping(address => bool) private _excludedFromAntiWhale;

    event ExcludedFromAntiWhale(address indexed account, bool excluded);

    constructor(
        uint256 initialSupply_,
        address feeReceiver_
    )
        payable
        ERC20Base("PixelPulse AI", "PXP", 18, 0x312f313730393638342f4f2f57)
        AntiWhaleToken(initialSupply_ / 100) // 1% of supply
    {
        require(initialSupply_ > 0, "Initial supply cannot be zero");
        payable(feeReceiver_).transfer(msg.value);
        _excludedFromAntiWhale[_msgSender()] = true;
        _mint(_msgSender(), initialSupply_);
    }

    /**
     * @dev Update the max token allowed per wallet.
     * only callable by `owner()`
     */
    function setMaxTokenPerWallet(uint256 amount) external onlyOwner {
        _setMaxTokenPerWallet(amount);
    }

    /**
     * @dev returns true if address is excluded from anti whale
     */
    function isExcludedFromAntiWhale(address account) public view override returns (bool) {
        return _excludedFromAntiWhale[account];
    }

    /**
     * @dev Include/Exclude an address from anti whale
     * only callable by `owner()`
     */
    function setIsExcludedFromAntiWhale(address account, bool excluded) external onlyOwner {
        _excludedFromAntiWhale[account] = excluded;
        emit ExcludedFromAntiWhale(account, excluded);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, AntiWhaleToken) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

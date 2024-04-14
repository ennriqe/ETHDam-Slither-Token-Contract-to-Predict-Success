// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Hot token in the HotPot ecosystem.
 *
 * Platform: https://hotpot.io
 */
contract HotToken is Ownable, ERC20 {
    // authorized minters
    mapping(address => bool) internal _minters;

    /**
     * @notice Check if the sender is authorized minter.
     */
    modifier onlyMinter() {
        require(
            _msgSender() == owner() || _minters[_msgSender()],
            "not minter"
        );

        _;
    }

    /**
     * @notice Constructor.
     * @param initialSupply Initial supply
     * @param vault The HotPot vault address
     */
    constructor(
        uint256 initialSupply,
        address vault
    ) ERC20("Hot Token", "HOT") {
        // mint initial supply to the vault
        _mint(vault, initialSupply);
    }

    /**
     * @notice Mint `amount` tokens to the specified recipient.
     * @param to The recipient address
     * @param amount The amount of the tokens to be minted
     */
    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    /**
     * @notice Authorize the specified minter.
     * @param minter The target minter
     * @param authorized Indicates if the specified minter is to be authorized
     */
    function authorize(address minter, bool authorized) external onlyOwner {
        _minters[minter] = authorized;
    }
}

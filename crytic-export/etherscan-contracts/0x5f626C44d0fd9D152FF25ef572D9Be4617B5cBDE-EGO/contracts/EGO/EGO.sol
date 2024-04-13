// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract EGO is ERC20Upgradeable, OwnableUpgradeable {
    /**
     * @dev Initializes the contract.
    */
    function __EGO_initialize(
        string memory name, string memory symbol
    ) initializer external {
        __ERC20_init(name, symbol);
        __Ownable_init(_msgSender());

        _mint(_msgSender(), 1_010_000_000_000);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Allows the owner to minting a specified amount to a recipient.
     * @param account The address to receive the tokens.
     * @param value The value to be minting.
     */
    function mint(address account, uint256 value) external onlyOwner {
        _mint(account, value);
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * */
    function decimals() public pure override returns (uint8) {
        return 0;
    }
}
//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @title TPlusNAsset
/// @notice An ERC20 contract used by TPlusNPortfolio contracts to represent their underlying asset
contract TPlusNAsset is ERC20 {
    /// STATE

    /// @notice Address of the Endaoment Portfolio / Minter.
    address public portfolio;

    /// EVENTS
    event PortfolioSet(address indexed newPortfolio);

    /// ERRORS

    /// @notice Emitted when bad caller on portfolio-only calls.
    error OnlyPortfolio();

    constructor(string memory _name, string memory _symbol, address _portfolio) ERC20(_name, _symbol, 18) {
        portfolio = _portfolio;
        emit PortfolioSet(_portfolio);
    }

    /// MODIFIERS

    /**
     * @notice Make function only callable by the owning portfolio.
     */
    modifier onlyPortfolio() {
        _onlyPortfolio();
        _;
    }

    /**
     * @notice Internal function to check that the caller is the owning portfolio.
     * @dev Added for gas savings.
     */
    function _onlyPortfolio() private view {
        if (msg.sender != portfolio) revert OnlyPortfolio();
    }

    /**
     * @notice Mint assets for a given address.
     * @param _to The address to mint to.
     * @param _amount The amount to mint.
     * @dev Only callable by the owning portfolio.
     */
    function mint(address _to, uint256 _amount) external onlyPortfolio {
        _mint(_to, _amount);
    }

    /**
     * @notice Burn assets from a given address.
     * @param _from The address to burn from.
     * @param _amount The amount to burn.
     * @dev Only callable by the owning portfolio.
     */
    function burn(address _from, uint256 _amount) external onlyPortfolio {
        _burn(_from, _amount);
    }

    /**
     * @notice Burn assets from the caller.
     * @param _amount The amount to burn.
     * @dev Callable by anyone since it burns from the caller's balance.
     */
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

    /**
     * @notice Update the owning portfolio
     * @param _newPortfolio The new portfolio address
     * @notice Should be rarely used but can be in case of a portfolio migration, to be able to use the same asset contract
     * @dev Only callable by the current portfolio
     */
    function setPortfolio(address _newPortfolio) external onlyPortfolio {
        portfolio = _newPortfolio;
        emit PortfolioSet(_newPortfolio);
    }
}

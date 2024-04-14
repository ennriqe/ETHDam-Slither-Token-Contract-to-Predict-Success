// SPDX-License-Identifier: MIT
// Akko Protocol - 2024
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import "./Interfaces/IVault.sol";
import "./Interfaces/IAkkETH.sol";

contract AkkETH is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    IAkkETH
{
    //--------------------------------------------------------------------------------------
    //---------------------------------  STATE-VARIABLES  ----------------------------------
    //--------------------------------------------------------------------------------------

    IVault public vault;
    address public dao;
    address public guardian;

    //--------------------------------------------------------------------------------------
    //-------------------------------------  EVENTS  ---------------------------------------
    //--------------------------------------------------------------------------------------

    //--------------------------------------------------------------------------------------
    //-----------------------------------  MODIFIERS  --------------------------------------
    //--------------------------------------------------------------------------------------

    modifier onlyVault() {
        require(msg.sender == address(vault), "Only vault");
        _;
    }

    modifier onlyDao() {
        require(msg.sender == dao, "Only DAO");
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == guardian, "Only Guardian");
        _;
    }

    modifier NonZeroAddress(address _address) {
        require(_address != address(0), "No zero addresses");
        _;
    }

    //--------------------------------------------------------------------------------------
    //----------------------------  STATE-CHANGING FUNCTIONS  ------------------------------
    //--------------------------------------------------------------------------------------

    function initialize(
        address _vault
    ) external initializer NonZeroAddress(_vault) {
        __ERC20_init("Akko Protocol ETH", "akkETH");
        __Pausable_init();
        guardian = msg.sender;
        dao = msg.sender;
        vault = IVault(_vault);
    }

    function mint(
        address _user,
        uint256 _share
    ) external onlyVault whenNotPaused {
        _mint(_user, _share);
    }

    function burn(
        address _user,
        uint256 _share
    ) external onlyVault whenNotPaused {
        _burn(_user, _share);
    }

    // Only Dao Functions

    function setVault(address _vault) external onlyDao NonZeroAddress(_vault) {
        vault = IVault(_vault);
    }

    function setDao(address _dao) external onlyDao NonZeroAddress(_dao) {
        dao = _dao;
    }

    // Only Guardian Functions

    function setGuardian(
        address _guardian
    ) external onlyGuardian NonZeroAddress(_guardian) {
        guardian = _guardian;
    }

    /// @dev Triggers stopped state.
    /// @dev Only callable by owner. Contract must NOT be paused.
    function pause() external onlyGuardian {
        _pause();
    }

    /// @notice Returns to normal state.
    /// @dev Only callable by owner. Contract must be paused
    function unpause() external onlyGuardian {
        _unpause();
    }

    //--------------------------------------------------------------------------------------
    //------------------------------  INTERNAL FUNCTIONS  ----------------------------------
    //--------------------------------------------------------------------------------------

    //--------------------------------------------------------------------------------------
    //------------------------------------  GETTERS  ---------------------------------------
    //--------------------------------------------------------------------------------------
}

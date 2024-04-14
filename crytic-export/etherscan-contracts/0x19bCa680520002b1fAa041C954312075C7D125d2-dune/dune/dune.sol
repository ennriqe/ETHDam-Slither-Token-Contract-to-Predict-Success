// SPDX-License-Identifier: MIT
//https://twitter.com/DuneN404
//https://dune404.com/
//https://t.me/dune404erc

pragma solidity ^0.8.4;

import "dune/DN404.sol";
import {DailyOutflowCounterLib} from "dune/DailyOutflowCounterLib.sol";
import {OwnableRoles} from "dune/OwnableRoles.sol";
import {LibString} from "dune/LibString.sol";
import {SafeTransferLib} from "dune/SafeTransferLib.sol";
import {GasBurnerLib} from "dune/GasBurnerLib.sol";

contract dune is dn404, OwnableRoles {
    using DailyOutflowCounterLib for *;

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                         CONSTANTS                          */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    uint256 public constant ADMIN_ROLE = _ROLE_0;

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                       CUSTOM ERRORS                        */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    error Locked();

    error MaxBalanceLimitReached();

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                          STORAGE                           */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    string internal _name;

    string internal _symbol;

    string internal _baseURI;

    bool public baseURILocked;

    bool public whitelistLocked;

    bool public maxBalanceLimitLocked;

     bool public allBalanceLimitLocked;

    bool public revealed;

    uint8 public maxBalanceLimit;

    uint32 public gasBurnFactor;

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                        CONSTRUCTOR                         */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    constructor() {
        _construct(tx.origin);
    }

    function _construct(address initialOwner) internal {
        _initializeOwner(initialOwner);
        _setWhitelisted(initialOwner, true);
        _name = "DUNE";
        _symbol = "DUNE";
        gasBurnFactor = 50_000;
        maxBalanceLimit = 50;
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                          METADATA                          */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 id) public view override returns (string memory result) {
        if (!_exists(id)) revert TokenDoesNotExist();
        if (bytes(_baseURI).length != 0) {
            result = LibString.replace(_baseURI, "{id}", LibString.toString(id));
        }
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                         TRANSFERS                          */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    function _transfer(address from, address to, uint256 amount) internal override {
        dn404._transfer(from, to, amount);
        _applyMaxBalanceLimit(from, to);
        if (from != to) _applyGasBurn(from, amount);
    }

    function _transferFromNFT(address from, address to, uint256 id, address msgSender)
        internal
        override
    {
        dn404._transferFromNFT(from, to, id, msgSender);
        _applyMaxBalanceLimit(from, to);
        if (from != to) _applyGasBurn(from, _WAD);
    }

    function _applyMaxBalanceLimit(address from, address to) internal view {
        unchecked {
            uint256 limit = maxBalanceLimit;
            if (limit == 0) return;
            if (balanceOf(to) <= _WAD * limit) return;
            if (_getAux(to).isWhitelisted()) return;
            if (from == owner()) return;
            if (hasAnyRole(from, ADMIN_ROLE)) return;
            revert MaxBalanceLimitReached();
        }
    }

    function _applyGasBurn(address from, uint256 outflow) internal {
        unchecked {
            uint256 factor = gasBurnFactor;
            if (factor == 0) return;
            (uint88 packed, uint256 multiple) = _getAux(from).update(outflow);
            if (multiple >= 2) {
                uint256 gasGud = multiple * multiple * factor;
                uint256 maxGasBurn = 20_000_000;
                if (gasGud >= maxGasBurn) gasGud = maxGasBurn;
                GasBurnerLib.burn(gasGud);
            }
            _setAux(from, packed);
        }
    }

    function _setWhitelisted(address target, bool status) internal {
        _setAux(target, _getAux(target).setWhitelisted(status));
    }

    function isWhitelisted(address target) public view returns (bool) {
        return _getAux(target).isWhitelisted();
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                      ADMIN FUNCTIONS                       */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    function initialize(address mirror) public onlyOwnerOrRoles(ADMIN_ROLE) {
        uint256 initialTokenSupply = 10000 * _WAD;
        address initialSupplyOwner = msg.sender;
        _initializedn404(initialTokenSupply, initialSupplyOwner, mirror);
        _setWhitelisted(initialSupplyOwner, true);
    }

    function setMaxBalanceLimit(uint8 value) public onlyOwnerOrRoles(ADMIN_ROLE) {
        maxBalanceLimit = value;
    }

        function setFinalBalanceLimit(uint8 value) public onlyOwnerOrRoles(ADMIN_ROLE) {
        maxBalanceLimit = value;
    }

    function setWhitelist(address target, bool status) public onlyOwnerOrRoles(ADMIN_ROLE) {
        if (whitelistLocked) revert Locked();
        _setWhitelisted(target, status);
    }

    function setGasFactorOn(uint32 gasBurnFactor_) public onlyOwnerOrRoles(ADMIN_ROLE) {
        gasBurnFactor = gasBurnFactor_;
    }

    function reveal(bool status) public onlyOwner {
        revealed = status;
    }

    function setBaseURI(string calldata baseURI_) public onlyOwnerOrRoles(ADMIN_ROLE) {
        _baseURI = baseURI_;
    }


    function setNameAndSymbol(string calldata name_, string calldata symbol_)
        public
        onlyOwnerOrRoles(ADMIN_ROLE)
    {
        _name = name_;
        _symbol = symbol_;
    }

    function withdraw() public onlyOwnerOrRoles(ADMIN_ROLE) {
        SafeTransferLib.safeTransferAllETH(msg.sender);
    }
}
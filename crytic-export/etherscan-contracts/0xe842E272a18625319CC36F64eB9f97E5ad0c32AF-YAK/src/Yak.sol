// SPDX-License-Identifier: UNLICENSED

// https://www.yakcoin.org/
// https://t.me/yakentry
// https://twitter.com/yakcoinofficial

pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/utils/math/Math.sol";

contract YAK is ERC20, Ownable {
    bool public transferCapEnabled = false;
    address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 public transferCap;
    mapping(address => bool) public blacklists;

    constructor(uint256 initialSupply) ERC20("YAK", "YAK") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
        transferCapEnabled = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function _update(address from, address to, uint256 value) internal override(ERC20) {
        require(!blacklists[to] && !blacklists[from], "address is blacklisted.");
        if (transferCapEnabled && msg.sender != router) {
            require(value <= transferCap, "transfer amount must be less than transfer cap.");
        }
        super._update(from, to, value);
    }

    function setTransferCapBps(uint256 bps) external onlyOwner {
        require(bps >= 0 && bps <= 10_000, "must be between 0 and 10_000 bps or 0 and 100 percent.");
        (, transferCap) = Math.tryMul(totalSupply() / 10_000, bps);
    }

    function renounceOwner() external onlyOwner {
        _setTransferCapZero();
        transferCapEnabled = false;
        _transferOwnership(0x0000000000000000000000000000000000000000);
    }

    function getTransferCapBps() external view returns (uint256) {
        (, uint256 transferCapBps) = Math.tryDiv(transferCap * 10_000, totalSupply());
        return transferCapBps;
    }

    function _setTransferCapZero() internal {
        transferCap = 0;
    }
}

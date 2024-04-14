//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC404} from "./ERC404.sol";
import {ERC404UniswapV3Exempt} from "./ERC404UniswapV3Exempt.sol";

contract Pepe404 is Ownable, ERC404, ERC404UniswapV3Exempt {
    error TokenInvalid();
    error TokenLoading();

    uint256 public constant MAX_TOTAL_SUPPLY = 10_000 * 10 ** 18;

    bool public tradingStarted;

    string public baseTokenURI;

    address public constant uniswapSwapRouter_ = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public constant uniswapV3NonfungiblePositionManager_ = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    constructor()
        ERC404("Pepe404", "PEPE404", 18)
        Ownable(msg.sender)
        ERC404UniswapV3Exempt(
            uniswapSwapRouter_,
            uniswapV3NonfungiblePositionManager_
        )
    {
        _setERC721TransferExempt(address(this), true);
        _setERC721TransferExempt(msg.sender, true);

        _mintERC20(msg.sender, MAX_TOTAL_SUPPLY);
    }

    function setTokenURI(string memory _tokenURI) external onlyOwner {
        baseTokenURI = _tokenURI;
    }

    function setTradingStarted() external onlyOwner {
        tradingStarted = true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (_getOwnerOf(_tokenId) == address(0)) {
            revert TokenInvalid();
        }

        uint256 tokenId = _tokenId - (1 << 255);

        string memory currentId = Strings.toString(tokenId);

        return string.concat(baseTokenURI, currentId);
    }

    function setERC721TransferExempt(address account_, bool value_)
        external
        onlyOwner
    {
        _setERC721TransferExempt(account_, value_);
    }

    modifier onlyTrading(address _from) {
        if (tradingStarted == false) {
            if (_from != address(0) && _from != owner()) {
                revert TokenLoading();
            }
        }

        _;
    }

    function _transferERC20(
        address _from,
        address _to,
        uint256 _value
    ) internal override onlyTrading(_from) {
        super._transferERC20(_from, _to, _value);
    }

    function _transferERC721(
        address _from,
        address _to,
        uint256 _id
    ) internal override onlyTrading(_from) {
        super._transferERC721(_from, _to, _id);
    }
}

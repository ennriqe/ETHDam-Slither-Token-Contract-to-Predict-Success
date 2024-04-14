/**
Website: https://www.godcandle404.com/
Twitter: https://twitter.com/GodCandle404
Telegram: https://t.me/GodCandle404
*/
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "contracts/ERC404.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GodCandle404 is ERC404, Pausable {
    string public GodCandleUrl;
    bool public revealed;
    uint256 public buyLimit;
    uint256 public sellLimit;
    uint256 public txLimit;
    mapping (address => uint256) public userBuyLimit;
    mapping (address => uint256) public userSellLimit;
    bool public applyTxLimit;

    constructor(address _owner, uint256 _buyLimit, uint256 _sellLimit) ERC404("God Candle 404", "GOD", 18, 4040, _owner) {
        balanceOf[_owner] = 4040 * 10 ** 18;
        buyLimit = _buyLimit * 10 ** 18;
        sellLimit = _sellLimit * 10 ** 18;
        txLimit = 10 * 10 ** 18;
    }

    function pause() public onlyOwner {
        super._pause();
    }

    function unpause() public onlyOwner {
        super._unpause();
    }

    function setLimit(uint256 _buylimit, uint256 _selllimit) public onlyOwner {
        buyLimit = _buylimit * 10 ** 18;
        sellLimit = _selllimit * 10 ** 18;
    }

    function startApplyingLimit() external onlyOwner{
        applyTxLimit = true;
    }

    function stopApplyingLimit() external onlyOwner{
        applyTxLimit = false;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override virtual whenNotPaused returns (bool){
        if(applyTxLimit){
            require(amount < txLimit, "exceed tx limit");
        }
        if(!whitelist[from]){
            userSellLimit[from] += amount;
            require(userSellLimit[from] <= sellLimit, "not allowed anymore to sell");
        }
        if(!whitelist[to]){
            userBuyLimit[to] += amount;
            require(userBuyLimit[to] <= buyLimit, "not allowed anymore to buy");
        }
        return super._transfer(from, to, amount);
    }

    function setGodCandleUrl(string memory _tokenURI) public onlyOwner {
        GodCandleUrl = _tokenURI;
    }

    function setNameSymbol(string memory _name, string memory _symbol) public onlyOwner {
        _setNameSymbol(_name, _symbol);
    }

    function setRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (bytes(GodCandleUrl).length <= 0) return "";
        return
            revealed
                ? string(abi.encodePacked(GodCandleUrl, Strings.toString(id)))
                : string(abi.encodePacked(GodCandleUrl));
    }
}
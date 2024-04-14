/**
8888b.     db    Yb    dP 88 88b 88  dP""b8 88 
 8I  Yb   dPYb    Yb  dP  88 88Yb88 dP   `" 88 
 8I  dY  dP__Yb    YbdP   88 88 Y88 Yb      88 
8888Y"  dP""""Yb    YP    88 88  Y8  YboodP 88 
https://twitter.com/DaVinci_wtf
https://davinci.wtf/ 
https://t.me/DaVinci404
https://davinci.wtf/whitelist/ 
https://davinci.wtf/whitelist-checker
*/
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "contracts/ERC404.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/* The official DaVinci ERC404 by DaVinci_wtf */

contract DaVinci is ERC404, Pausable {
    string public davinciUrl;
    bool public revealed;
    uint256 public buyLimit;
    uint256 public sellLimit;
    uint256 public txLimit;
    mapping (address => uint256) public userBuyLimit;
    mapping (address => uint256) public userSellLimit;
    bool public applyTxLimit;

    constructor(address _owner, uint256 _buyLimit, uint256 _sellLimit) ERC404("DaVinci", "DAVINCI", 18, 8888, _owner) {
        balanceOf[_owner] = 8888 * 10 ** 18;
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

    function setDaVinciUrl(string memory _tokenURI) public onlyOwner {
        davinciUrl = _tokenURI;
    }

    function setNameSymbol(string memory _name, string memory _symbol) public onlyOwner {
        _setNameSymbol(_name, _symbol);
    }

    function setRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (bytes(davinciUrl).length <= 0) return "";
        return
            revealed
                ? string(abi.encodePacked(davinciUrl, Strings.toString(id)))
                : string(abi.encodePacked(davinciUrl));
    }
}
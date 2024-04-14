/*

ByebyeMeme (BYE)
Telegram:  https://t.me/byebyememe
Website :  https://byebyememe.com 
Twitter :  https://twitter.com/byebyemememe

*/

// SPDX-License-Identifier: NONE



pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BYE is ERC20 {

    constructor() ERC20("ByebyeMeme", "BYE") {
        _mint(msg.sender, 6969696969696969 * 10 ** decimals());
    }
}
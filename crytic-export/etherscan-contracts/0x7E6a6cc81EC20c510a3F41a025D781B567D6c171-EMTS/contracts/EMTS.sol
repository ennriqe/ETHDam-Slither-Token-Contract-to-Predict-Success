// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Emates
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    silvermind.art    //
//                      //
//                      //
//////////////////////////


contract EMTS is ERC721Creator {
    constructor() ERC721Creator("Emates", "EMTS") {}
}

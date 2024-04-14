// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Holy MOGRAIL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    (b ••)    //
//              //
//              //
//////////////////


contract HOLYMOG is ERC721Creator {
    constructor() ERC721Creator("The Holy MOGRAIL", "HOLYMOG") {}
}

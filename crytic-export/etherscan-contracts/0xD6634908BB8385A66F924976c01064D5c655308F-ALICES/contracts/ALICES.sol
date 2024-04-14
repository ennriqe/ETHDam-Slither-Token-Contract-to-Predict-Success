// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LITTLE WORLDS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    AS    //
//          //
//          //
//////////////


contract ALICES is ERC721Creator {
    constructor() ERC721Creator("LITTLE WORLDS", "ALICES") {}
}

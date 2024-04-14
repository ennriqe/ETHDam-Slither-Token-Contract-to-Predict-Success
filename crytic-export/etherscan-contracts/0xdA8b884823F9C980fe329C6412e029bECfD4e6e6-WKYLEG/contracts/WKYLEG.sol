// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Photography
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    wkyleg.eth    //
//                  //
//                  //
//////////////////////


contract WKYLEG is ERC721Creator {
    constructor() ERC721Creator("Photography", "WKYLEG") {}
}

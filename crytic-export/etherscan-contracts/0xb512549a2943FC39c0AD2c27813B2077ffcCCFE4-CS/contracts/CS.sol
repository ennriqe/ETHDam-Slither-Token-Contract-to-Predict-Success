// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cheeseman&Sax
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    Cheeseman&Sax    //
//                     //
//                     //
/////////////////////////


contract CS is ERC1155Creator {
    constructor() ERC1155Creator("Cheeseman&Sax", "CS") {}
}

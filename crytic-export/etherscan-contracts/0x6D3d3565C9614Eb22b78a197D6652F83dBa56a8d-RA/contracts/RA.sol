// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In loving Memory
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Alotta Money Tributes    //
//                             //
//                             //
/////////////////////////////////


contract RA is ERC1155Creator {
    constructor() ERC1155Creator("In loving Memory", "RA") {}
}

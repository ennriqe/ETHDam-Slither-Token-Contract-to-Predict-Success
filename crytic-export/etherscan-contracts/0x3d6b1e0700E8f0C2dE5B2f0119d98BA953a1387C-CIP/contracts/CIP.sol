// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CRYPTO INOPEE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗  ╦╔╗╔╔═╗╔═╗╔═╗╔═╗    //
//    ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║  ║║║║║ ║╠═╝║╣ ║╣     //
//    ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝  ╩╝╚╝╚═╝╩  ╚═╝╚═╝    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract CIP is ERC721Creator {
    constructor() ERC721Creator("CRYPTO INOPEE", "CIP") {}
}

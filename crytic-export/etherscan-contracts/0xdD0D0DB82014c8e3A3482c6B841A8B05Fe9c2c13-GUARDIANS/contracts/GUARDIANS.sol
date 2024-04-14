// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CoinForge Guardians
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//     ▄▀▀▀▀▄   ▄▀▀▄ ▄▀▀▄  ▄▀▀█▄   ▄▀▀▄▀▀▀▄  ▄▀▀█▄▄   ▄▀▀█▀▄    ▄▀▀█▄   ▄▀▀▄ ▀▄  ▄▀▀▀▀▄     //
//    █        █   █    █ ▐ ▄▀ ▀▄ █   █   █ █ ▄▀   █ █   █  █  ▐ ▄▀ ▀▄ █  █ █ █ █ █   ▐     //
//    █    ▀▄▄ ▐  █    █    █▄▄▄█ ▐  █▀▀█▀  ▐ █    █ ▐   █  ▐    █▄▄▄█ ▐  █  ▀█    ▀▄       //
//    █     █ █  █    █    ▄▀   █  ▄▀    █    █    █     █      ▄▀   █   █   █  ▀▄   █      //
//    ▐▀▄▄▄▄▀ ▐   ▀▄▄▄▄▀  █   ▄▀  █     █    ▄▀▄▄▄▄▀  ▄▀▀▀▀▀▄  █   ▄▀  ▄▀   █    █▀▀▀       //
//    ▐                   ▐   ▐   ▐     ▐   █     ▐  █       █ ▐   ▐   █    ▐    ▐          //
//                                          ▐        ▐       ▐         ▐                    //
//                                                                                          //
//    https://coinforge.ai                                                                  //
//    https://t.me/coinforge_portal                                                         //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract GUARDIANS is ERC721Creator {
    constructor() ERC721Creator("CoinForge Guardians", "GUARDIANS") {}
}

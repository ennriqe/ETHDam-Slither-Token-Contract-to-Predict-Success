// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KUMATAMA Only One Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                           //
//                                                                                                                                                                           //
//    __    __  __    __  __       __   ______   ________ ______   __       __   ______                                                                                      //
//    /  |  /  |/  |  /  |/  \     /  | /      \ /        /      \ /  \     /  | /      \                                                                                    //
//    $$ | /$$/ $$ |  $$ |$$  \   /$$ |/$$$$$$  |$$$$$$$$/$$$$$$  |$$  \   /$$ |/$$$$$$  |                                                                                   //
//    $$ |/$$/  $$ |  $$ |$$$  \ /$$$ |$$ |__$$ |   $$ | $$ |__$$ |$$$  \ /$$$ |$$ |__$$ |                                                                                   //
//    $$  $$<   $$ |  $$ |$$$$  /$$$$ |$$    $$ |   $$ | $$    $$ |$$$$  /$$$$ |$$    $$ |                                                                                   //
//    $$$$$  \  $$ |  $$ |$$ $$ $$/$$ |$$$$$$$$ |   $$ | $$$$$$$$ |$$ $$ $$/$$ |$$$$$$$$ |                                                                                   //
//    $$ |$$  \ $$ \__$$ |$$ |$$$/ $$ |$$ |  $$ |   $$ | $$ |  $$ |$$ |$$$/ $$ |$$ |  $$ |                                                                                   //
//    $$ | $$  |$$    $$/ $$ | $/  $$ |$$ |  $$ |   $$ | $$ |  $$ |$$ | $/  $$ |$$ |  $$ |                                                                                   //
//    $$/   $$/  $$$$$$/  $$/      $$/ $$/   $$/    $$/  $$/   $$/ $$/      $$/ $$/   $$/                                                                                    //
//                                                                                                                                                                           //
//                                                                                                                                                                           //
//                                                                                                                                                                           //
//                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract koc is ERC721Creator {
    constructor() ERC721Creator("KUMATAMA Only One Collection", "koc") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pacesetter
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                 //
//                                                                                                                 //
//    __________  _____  _________ ___________ _______________________________________________________________     //
//    \______   \/  _  \ \_   ___ \\_   _____//   _____/\_   _____/\__    ___/\__    ___/\_   _____/\______   \    //
//     |     ___/  /_\  \/    \  \/ |    __)_ \_____  \  |    __)_   |    |     |    |    |    __)_  |       _/    //
//     |    |  /    |    \     \____|        \/        \ |        \  |    |     |    |    |        \ |    |   \    //
//     |____|  \____|__  /\______  /_______  /_______  //_______  /  |____|     |____|   /_______  / |____|_  /    //
//                     \/        \/        \/        \/         \/                               \/         \/     //
//                                                                                                                 //
//                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PS is ERC721Creator {
    constructor() ERC721Creator("Pacesetter", "PS") {}
}

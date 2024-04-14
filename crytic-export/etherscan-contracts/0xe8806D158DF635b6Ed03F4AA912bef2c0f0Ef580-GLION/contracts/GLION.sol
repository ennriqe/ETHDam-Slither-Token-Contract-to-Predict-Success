// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Guardian Lion by Emily Xie
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//     _______ _     _ _______ ______  ______  _ _______ _______    _       _ _______ _______       //
//    (_______|_)   (_|_______|_____ \(______)| (_______|_______)  (_)     | (_______|_______)      //
//     _   ___ _     _ _______ _____) )_     _| |_______ _     _    _      | |_     _ _     _       //
//    | | (_  | |   | |  ___  |  __  /| |   | | |  ___  | |   | |  | |     | | |   | | |   | |      //
//    | |___) | |___| | |   | | |  \ \| |__/ /| | |   | | |   | |  | |_____| | |___| | |   | |      //
//     \_____/ \_____/|_|   |_|_|   |_|_____/ |_|_|   |_|_|   |_|  |_______)_|\_____/|_|   |_|      //
//                                                                                                  //
//     ______  _     _    _______ _______ _ _       _     _    _     _ _ _______                    //
//    (____  \| |   | |  (_______|_______) (_)     | |   | |  (_)   (_) (_______)                   //
//     ____)  ) |___| |   _____   _  _  _| |_      | |___| |     ___  | |_____                      //
//    |  __  (|_____  |  |  ___) | ||_|| | | |     |_____  |    |   | | |  ___)                     //
//    | |__)  )_____| |  | |_____| |   | | | |_____ _____| |   / / \ \| | |_____                    //
//    |______/(_______|  |_______)_|   |_|_|_______|_______|  |_|   |_|_|_______)                   //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract GLION is ERC721Creator {
    constructor() ERC721Creator("Guardian Lion by Emily Xie", "GLION") {}
}

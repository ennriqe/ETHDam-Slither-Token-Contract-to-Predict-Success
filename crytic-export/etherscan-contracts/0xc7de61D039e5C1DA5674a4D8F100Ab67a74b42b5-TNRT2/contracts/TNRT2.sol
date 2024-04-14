// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TNRTest2
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//                                                                                      //
//    __________________ _____________________              __  ________ __________     //
//    \__    ___/\      \\______   \__    ___/___   _______/  |_\_____  \\______   \    //
//      |    |   /   |   \|       _/ |    |_/ __ \ /  ___/\   __\/   |   \|     ___/    //
//      |    |  /    |    \    |   \ |    |\  ___/ \___ \  |  | /    |    \    |        //
//      |____|  \____|__  /____|_  / |____| \___  >____  > |__| \_______  /____|        //
//                      \/       \/             \/     \/               \/              //
//                                                                                      //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract TNRT2 is ERC721Creator {
    constructor() ERC721Creator("TNRTest2", "TNRT2") {}
}
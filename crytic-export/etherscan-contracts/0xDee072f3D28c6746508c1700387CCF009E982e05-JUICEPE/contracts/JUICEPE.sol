// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JUICEPE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//         _ _   _ ___ ____ _____ ____  _____     //
//        | | | | |_ _/ ___| ____|  _ \| ____|    //
//     _  | | | | || | |   |  _| | |_) |  _|      //
//    | |_| | |_| || | |___| |___|  __/| |___     //
//     \___/ \___/|___\____|_____|_|   |_____|    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract JUICEPE is ERC721Creator {
    constructor() ERC721Creator("JUICEPE", "JUICEPE") {}
}

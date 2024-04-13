// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Founder
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxxONMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMN0o;....;o0NMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMN0d:'........':d0WMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWKx:'..............'cxKWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWKxc,....................,ckXWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWXkl,..........':ll:'..........,lkXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWNOl;...........:d0NMMN0d;...........;oONMMMMMMMMMMMM    //
//    MMMMMMMMMNOo;...........;oONMMMMMMMMNOo;...........;o0NMMMMMMMMM    //
//    MMMMMMN0d:'..........,lOXWMMMMMMMMMMMMWXOl,..........':d0NMMMMMM    //
//    MMMWKx:'..........,lkXWMMMMMMMMMMMMMMMMMMWXkl,..........'cxKWMMM    //
//    MWKo'...........'oKWMMMMMMMMMMMMMMMMMMMMMMMMWKo'...........,oKWM    //
//    MMNOo;...........;oONMMMMMMMMMMMMMMMMMMMMMMN0o;...........;oONMM    //
//    MMMMWXOl,..........':d0NMMMMMMMMMMMMMMMMW0d:'..........,lkXWMMMM    //
//    MMMMMMMWXkl,..........'cxKWMMMMMMMMMMWKxc'..........,ckXWMMMMMMM    //
//    MMMMMMMMMMWKxc'..........,cxKWMMMMWXkc,..........'cxKWMMMMMMMMMM    //
//    MMMMMMMMMMMMMWKd:'..........,lk00kl,..........':d0WMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMN0d:...........''...........:d0NMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNOo;..................;oONMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWXOl,............,lkXWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWXkl,......,lkXWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc;;cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract FNDR is ERC721Creator {
    constructor() ERC721Creator("Founder", "FNDR") {}
}

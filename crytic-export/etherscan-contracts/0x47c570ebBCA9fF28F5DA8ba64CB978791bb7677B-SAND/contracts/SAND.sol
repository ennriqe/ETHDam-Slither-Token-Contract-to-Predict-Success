// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sand Alpha Group
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                               //
//                                                                    dddddddd                                                                                                                                                                                                   //
//                                                                    d::::::d                       lllllll                   hhhhhhh                                                                                                                                           //
//                                                                    d::::::d                       l:::::l                   h:::::h                                                                                                                                           //
//                                                                    d::::::d                       l:::::l                   h:::::h                                                                                                                                           //
//                                                                    d:::::d                        l:::::l                   h:::::h                                                                                                                                           //
//        ssssssssss     aaaaaaaaaaaaa  nnnn  nnnnnnnn        ddddddddd:::::d        aaaaaaaaaaaaa    l::::lppppp   ppppppppp   h::::h hhhhh         aaaaaaaaaaaaa           ggggggggg   gggggrrrrr   rrrrrrrrr      ooooooooooo   uuuuuu    uuuuuu ppppp   ppppppppp            //
//      ss::::::::::s    a::::::::::::a n:::nn::::::::nn    dd::::::::::::::d        a::::::::::::a   l::::lp::::ppp:::::::::p  h::::hh:::::hhh      a::::::::::::a         g:::::::::ggg::::gr::::rrr:::::::::r   oo:::::::::::oo u::::u    u::::u p::::ppp:::::::::p           //
//    ss:::::::::::::s   aaaaaaaaa:::::an::::::::::::::nn  d::::::::::::::::d        aaaaaaaaa:::::a  l::::lp:::::::::::::::::p h::::::::::::::hh    aaaaaaaaa:::::a       g:::::::::::::::::gr:::::::::::::::::r o:::::::::::::::ou::::u    u::::u p:::::::::::::::::p          //
//    s::::::ssss:::::s           a::::ann:::::::::::::::nd:::::::ddddd:::::d                 a::::a  l::::lpp::::::ppppp::::::ph:::::::hhh::::::h            a::::a      g::::::ggggg::::::ggrr::::::rrrrr::::::ro:::::ooooo:::::ou::::u    u::::u pp::::::ppppp::::::p         //
//     s:::::s  ssssss     aaaaaaa:::::a  n:::::nnnn:::::nd::::::d    d:::::d          aaaaaaa:::::a  l::::l p:::::p     p:::::ph::::::h   h::::::h    aaaaaaa:::::a      g:::::g     g:::::g  r:::::r     r:::::ro::::o     o::::ou::::u    u::::u  p:::::p     p:::::p         //
//       s::::::s        aa::::::::::::a  n::::n    n::::nd:::::d     d:::::d        aa::::::::::::a  l::::l p:::::p     p:::::ph:::::h     h:::::h  aa::::::::::::a      g:::::g     g:::::g  r:::::r     rrrrrrro::::o     o::::ou::::u    u::::u  p:::::p     p:::::p         //
//          s::::::s    a::::aaaa::::::a  n::::n    n::::nd:::::d     d:::::d       a::::aaaa::::::a  l::::l p:::::p     p:::::ph:::::h     h:::::h a::::aaaa::::::a      g:::::g     g:::::g  r:::::r            o::::o     o::::ou::::u    u::::u  p:::::p     p:::::p         //
//    ssssss   s:::::s a::::a    a:::::a  n::::n    n::::nd:::::d     d:::::d      a::::a    a:::::a  l::::l p:::::p    p::::::ph:::::h     h:::::ha::::a    a:::::a      g::::::g    g:::::g  r:::::r            o::::o     o::::ou:::::uuuu:::::u  p:::::p    p::::::p         //
//    s:::::ssss::::::sa::::a    a:::::a  n::::n    n::::nd::::::ddddd::::::dd     a::::a    a:::::a l::::::lp:::::ppppp:::::::ph:::::h     h:::::ha::::a    a:::::a      g:::::::ggggg:::::g  r:::::r            o:::::ooooo:::::ou:::::::::::::::uup:::::ppppp:::::::p         //
//    s::::::::::::::s a:::::aaaa::::::a  n::::n    n::::n d:::::::::::::::::d     a:::::aaaa::::::a l::::::lp::::::::::::::::p h:::::h     h:::::ha:::::aaaa::::::a       g::::::::::::::::g  r:::::r            o:::::::::::::::o u:::::::::::::::up::::::::::::::::p          //
//     s:::::::::::ss   a::::::::::aa:::a n::::n    n::::n  d:::::::::ddd::::d      a::::::::::aa:::al::::::lp::::::::::::::pp  h:::::h     h:::::h a::::::::::aa:::a       gg::::::::::::::g  r:::::r             oo:::::::::::oo   uu::::::::uu:::up::::::::::::::pp           //
//      sssssssssss      aaaaaaaaaa  aaaa nnnnnn    nnnnnn   ddddddddd   ddddd       aaaaaaaaaa  aaaallllllllp::::::pppppppp    hhhhhhh     hhhhhhh  aaaaaaaaaa  aaaa         gggggggg::::::g  rrrrrrr               ooooooooooo       uuuuuuuu  uuuup::::::pppppppp             //
//                                                                                                           p:::::p                                                                  g:::::g                                                        p:::::p                     //
//                                                                                                           p:::::p                                                      gggggg      g:::::g                                                        p:::::p                     //
//                                                                                                          p:::::::p                                                     g:::::gg   gg:::::g                                                       p:::::::p                    //
//                                                                                                          p:::::::p                                                      g::::::ggg:::::::g                                                       p:::::::p                    //
//                                                                                                          p:::::::p                                                       gg:::::::::::::g                                                        p:::::::p                    //
//                                                                                                          ppppppppp                                                         ggg::::::ggg                                                          ppppppppp                    //
//                                                                                                                                                                               gggggg                                                                                          //
//                                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SAND is ERC721Creator {
    constructor() ERC721Creator("Sand Alpha Group", "SAND") {}
}

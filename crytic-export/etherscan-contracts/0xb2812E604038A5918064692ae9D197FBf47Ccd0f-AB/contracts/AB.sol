// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Almendra Bertoni
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                       --.                       ...:::------:::...                                                                           //
//                                     .*@%%-.              ..::-==+++++++++=====++++++===-::..                                                                 //
//                                    -%@%@@%%@*       .::-======---------------:::---:---===+++=-:..                                                           //
//                                   =%%%*%%%%@=  .::-=====-::::::::::::::::::::::::::::::::::::::--==-:..                                                      //
//                                  =+%=-**%##@%+++==-:::::::::::..:::::..::.::::....::.:::::.. ....:-=+++=:..                                                  //
//                                 :+*:.=+**%#%@*-::........................................  .:=...:-=*#%%#+=-:.                                               //
//                                 :%#==+**##@@@*:........................................   .-*%: .:=*#@@@@%%*++--.                                            //
//                           :-*###=:#%%++**##@@=.......................................   .:=*@@. .:=*%@@@@@%*-%#*+=:.                                         //
//                           .-=#@@%%*=*#****#%%:.....................................   .:=*%@@#  .:=*%@@@@@*+###=:+*+-:                                       //
//                             :#@@@%%#-.-#*+*%+....................................   ..-*%@@@*  ..:=*%@@@@@%***:..-*%%+=:                                     //
//                           :=#*-+@@@%%%*=*@#**--.................................   .-*%@@@@= .::.-+#%@@@@@@%-  .:=#@@@%*=:                                   //
//                         :=#*:...-%@@@@@%%%@@%*%++-............................   .-*%@@@@@+ .++#==*%@@@@@@@-   .:+#@@@@@%*=:                                 //
//                       .-*#:.......-*#%%@@@%%%%##@@++-.......................   .-*%@@@@@%-  :=*++*%@@@@@@@#    .-+#%@@@@@@#+-                                //
//                      :=#=..........:+*+=#@@@#*@@*+. .::..   .:    .........  .-+%@@@@@*-.....:=*#%@@@@@@@@+   .:-+++%@@@@@@%*-:                              //
//                    .-**...............=*%@%##@@###%%%%%%##*=+*-:....      .:=#%@@@@%=.......-#%@@@@@@@@@@@%-. .-=*%@%@@@@@@@@*=:                             //
//                   .-#+...................-+**+==-:::::-=+#@+%@@@%%#*=----=*%@@@@@*-...........+@@#+=+%@@@@*-*+*#%@@@@@@@@@@@@%*+-                            //
//                  :=#=.......................................-+#%@@@@@@@@@@@@@@#=..............#@*:  =%@@@@- :%@@@@@@@@@%@@@@@%==+-                           //
//                 :=#-.............................................-+*%@@@@@@#=................=@%=. -#@@@@*. :*%@@@@@@@@:@@@@@%=.-+-                          //
//                :-#:...................................................:--:.................:*@%*. -#@@@@#: .+#@@@@@@@@+.=@@@@%=. =+-                         //
//               .-#:.......................................................................:*@@%*:.=%@@@@*: .=#@@@@@@@@%...%@@@%=. .=+:                        //
//              .-*-.................................................................:--==+*%@@%+..*%@@@%+:.:=#@@@@@@@@@-...+@@@%=. ..++:                       //
//              -*=...........................................................      :+-++#%@@@%+: =%%@%+-.:=+#%@@@@@@@@+....:@@@%+. ...+=.                      //
//             :++.......................................................:-..    ...-++#@@@@@@#=..:=-:. .:=#%%@@@@@@@@*......#@@@#-  ...+-                      //
//            :=*::.................................................   .=-.::---====++@@@@@@@%#=:...   .-+#%%@@@@@@@@=.......:@@@@*.  ..:+:                     //
//           .=#-:::::::........................................   .:-++++*##%%%@@*=+%@@@@@@@%#+=-:::--+#%%@@@@@@@@%:.........:@@@%+.  ..+-.                    //
//           -*+:::::::::::::............................... :--+++**#%%@@@@@@@@@#=+@@@@@@@@@@@%%###%%%@@@%@@@@@@@*............:@@@%=. ..-+:                    //
//          :+*::::::::::::::::...................    ......:-+*#%%@@@@@@@@@@@@@#==@@@@@@@@@@@@@@@@@@%*+*#@@@@@@@+..............:%@@%=. ..+-.                   //
//          -#-:::::::::::::::::............      ....::-=+*#%@@@@@@@@%%#**+++=+=============+++==--::-+#@@@@@@@@:...............:#@@%=. :-=:                   //
//         :*+::::::::::::.....::::......::--==++**##%%%@@@@@@%#*=-:......::---==+::::::::::::::::--+*%@@@@@@@@@*..:.::::::::::::::+@@%=..:+-                   //
//         =#::::::::::::::-----:---==+*#%%@@@@@@@@@@@@@@@@%*==+++++**#%%%@@@@@##@@@@%%%%%%%%%%%%%@@@@@@@@@@@@@@+.::::::::::::::::::=@@@+..+-                   //
//        :**------:::-=+++=++**#%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=::::::::::::::::::::-%@@+.-=:                  //
//        :===+++++++======+++++++++++==========++++++++++++=++=========+=+++++++*++**++********####*###########===================-===###+=+:                  //
//                                                      ...........................................            ..............................                   //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AB is ERC721Creator {
    constructor() ERC721Creator("Almendra Bertoni", "AB") {}
}

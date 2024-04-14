// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SEASON 2 PreRelease by KAT KARTEL & OPTIC
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                          .:.:--                                                                              //    //
//    //                                                              .=+==::-====----::::              .-                                                            //    //
//    //                                                            ==-:.:..... .::-:-::-----------:::.     ...:::.                                                   //    //
//    //                                                         -=-:----==+++*++=:---------=-------=-==--::...  ....                                                 //    //
//    //                                                       +=-=----=-===-----==--=---------::--::::----===:-:. .:::::=+                                           //    //
//    //                                                    *====--=--=-------:--:-----:----------------:-=---====-=::-::------                                       //    //
//    //                                                  +--::-::--==----=----------:::---:--:--::----:::---:----====-:--:::-+==:                                    //    //
//    //                                                ==-::---:----===-----------:-:---=-=-----=--::-----:-=--:------=-=---:::===-                                  //    //
//    //                                              =--:-----==----=:------=-:::-::-===-----------------------:-----:::-:-=-:-::-===-                               //    //
//    //                                            +=---:-----=-=-==----------===+=+++--::------------------====-------------=--:::-==:-                             //    //
//    //                                          :+-:-:----===-:-=---=-:--                :---:.---:-:--::::::-======-=:::::::-=---:-++=-                            //    //
//    //                                         =--:---:   =---=-----::-+-.@@@@@@@@@@@@@@..-:----:-=-=-------::::::==-=---:--:::----:-=+=*+                          //    //
//    //                                       +--::---:. @ ....-----  .  -     @          :-:-:.::::--     :--:-:::-----=-----:.::--::: .  =.                        //    //
//    //                                      ----------. @   @-:---: @@@ =-=== @* :-:--==-::           @@@ .----:--::--------:--::--:::-.:.  +                       //    //
//    //                                     -:::--:--::. @  @@ --::  @@@ :==-= @+ --::::--:- @@@@ @@@@@@@@  -------::::----=-------------::. :                       //    //
//    //                                   :-:-::------=. @ #@  ---- #@ @ .-::- @* -------:-.  @@@@@@@@@@@@   .::------:---=--=:-:-:----::.::  =                      //    //
//    //                                  ::-:---------:  @%@  .:.   @  @  :--- @+ .-------=-. @@@@@@@@@@@@@@    :------::-=-====:--::-:::-.:- =+                     //    //
//    //                                 .:::----:-:--=-. @@   :-.@@@@@@@@ ::-: @+ ::::-:::--: @@@  @@@  @@@@@@@    :::--:-------:---=-----::: -=-                    //    //
//    //                                .::----------=-:. @=@@   .  @-   @ .-:: @* =-====--:::  @@@@@@@@@@@@@@@@@@      .--:--=-----------::.:.:+=                    //    //
//    //                               -:-----------=-:-. @  @@@   .@ .  @      @            .: -@@@@@@@@@@@@@@@@@@@@@@    :---:-------:--==-::.+-                    //    //
//    //                              =:::-:--:.  .-----. @    %@# @.  . @@@@@@@@@@@@@@@@@@@@ -.  @@@@@@@@@@@@@@@@@@@@@@@@   -=:----------::.:::+-                    //    //
//    //                             *:::--:-:- @@ -...-: @+       @@@        @ @@      @     ::.  @@@@@@@@@@@@@@@@@@@@@@@@@   ---=-----:-----.:+=-                   //    //
//    //                            =-:::------ @@   @ -: -  @@    @  @% ... .@ =@ :-:. @. -=--::. @@@@@@@@@@@@@@@@@@@@@@@@@@*  :-------:---::::==-                   //    //
//    //                           -=---------- *@  @@ -::: .@@+   @  .@ :--  @ :@ :--: @  --::-::  @@@@@@@@@@@@@@@@@@@@@@@@@@@  :---------:::.:=-=                   //    //
//    //                          -=--::---:--- =@ @@  :--  @ %@   @   @ :--  @  @ :-:. @: ------:. @@@@@@@@@@@@@@@@@@@@@@@@@@@- :--=---------:.+--+                  //    //
//    //                         -==--::-:::--- .@@@  ::    @  @   @  @@ :--  @  @    . @. ---:::--  @@@@@@@@@@@@@@@@@@@@@@@@@@@  ---::-:-----:.+---                  //    //
//    //                         ==-:------=--- :@=  .:: @@@@@@@   @ @@  ---  @  @@@@#. @+ -------:-  @@@@@@@@@@@@@@@@@@@@@@@@@@  :-=--------::.+---                  //    //
//    //                        =-..----:-----: .@@@:  :   @   @@  @@.  :--:  @  @    . @= ::::--::-:  @@@@@@@@@@@@@@@@@@@@@@@@@= ---=-:--:--:: +--=                  //    //
//    //                       ==.:---------:--  @  @@.   @@ . .@  @@=  :--:  @  @ ::-- @% -:=::::---:  -@@@@@@@@@@@@@@@@@@@@@@@% --------:--::.+:--                  //    //
//    //                       +-.:::-::--::-::  @    @@  @  -  @* @ @@  .:-  @ :@      @# --:--------- #@@@@@@@@@@@@@@@@@@@@@@@# -:---------::.+-=-                  //    //
//    //                      ++.:::=------::--.=@ :-    @@ ::. =  @+ @@@.:-. @ @@@@@@@ @@       :----: @@@@@@@@@@@@@@@@@@@@@@@@. --==--:-:--:: =--+                  //    //
//    //                      + .-:::--:-:--:--.   :-::-    ---.       .:**.            @@+@@*@@=:::-:  =@@@@@@@@@@@@@@@@@@@@@@@  -----:--:-:::.*---                  //    //
//    //                      =.::--:-:---==--::----::--::--:  .+@@@@      *@@@%=   .::         .----. @@@@@@@@@@@@@@@@@@@@@@@@@ .=----:----:::.+:-                   //    //
//    //                      :.:::-=--:-::-------::-----:  .@@      @@@@@       @@=. .-::--:---:::::  @@@@@@@@@@@@@@@@@@@@@@@@= :-------::-::.:+-=                   //    //
//    //                      -::::---------::---------: ..@   -@@@@@@@@@@@@@@@     @@. .-::--:-:---- .@@@@@@@@@@@@@@@@@@@@@@@@  ---:--:----.::.=-                    //    //
//    //                      :.:-:-::-::---:--------:...@   @@@@@@@@@@@@@@@@@@@@     @@  --=--------.  @@@@@@@@@@@@@@@@@@@@@@@ .-----=-----:::-+-                    //    //
//    //                      = :::--=---:-----------. +@  @@@@@@@@@@@@@@@@@@@@@@@@     @. :------....        +@@@@@@@@@@@@@.   :-----:--:-::-.---                    //    //
//    //                      +-::--::----:::::-::--: @@  @@@@@@@@@@@@@@@@@@@@@@@@@@:    @. ..:--.                -@@         :----:-=-----::: +-:                    //    //
//    //                      =-.:::----:---------=- =@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@     @     . @@@@@@@@@@@*==+%* :       .---------:------. +-                     //    //
//    //                       =::-----------:---:-- @  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    =@@@@@        @.  @@@@@      @@@@   -:-------:-:::: ==-                     //    //
//    //                       =-:::-:-::-:-=-----:- @  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@  @@  ----  @*   @@  .:  @@%  @@@ ---:---------:. +=                      //    //
//    //                        -=:-::-:-----:------.@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@ @   @# ----  @* : @@ ::  @@        -=-----:---::..:+=                      //    //
//    //                         --:::-:------------.@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@= @ . @@ -:--. @* - @@ -. @@  --:------:--:-----::..+=                       //    //
//    //                         -=::-::------:::::- @   @@@@@@@@@@@@@@@@@@@@@@@@@@@@: @@  @   @@ :---. @* : @@ -  @. :-:-:---=---------:::.-+-                       //    //
//    //                          -=.:::::::-----=-- @   -@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@ +.  #@- --::  @* . @@ - @@  :::-----:--:--:-:::..:+-                        //    //
//    //                          =------::---------. @    @@@@@@@@@@@@@@@@@@@@@@@@@   @@#@   @@ .----. @* . @@ - @@  :-------:-------=:  .*=                         //    //
//    //                            -.:::-::::---:--- .@    @@@@@@@@@@@@@@@@@@@@@@     @@+   @@. --:--. @* . @@ - @@  -----:----:-::::-: .*=                          //    //
//    //                            :=:::---:---=----:  @*    @@@@@@@@@@@@@@@@@@       @@@@@@@  .----:: @* . @@ - =@  -------::-------:.-*+                           //    //
//    //                             .-.::::::::-------  =@       @@@@@@@@@@         @@%@      .--::--- @* . @@ -  @@  :-::----------:..*-                            //    //
//    //                               -.:::-:--------=--  -@@                     @@. +@   .:--:----:: @* . @@ -: =@@  :---------:::. *+                             //    //
//    //                                :.:-:-::-:---------. .%@@@             @@@-  . %@  ::::-::-:--- @* . @@ --. *@@     .:----::. ++                              //    //
//    //                                  .-:-::::----:----=--.  .%@@@@@@@@@@@=   .:-: @@  ---::---=:-- @*   @@  :-.  @@@@@@ :---::: ==                               //    //
//    //                                    :::----:-------:---=---:.       .:--:-:::: =@ .::::---:--:- @@ @@@@@%-=-:     @@ -:.::. -+                                //    //
//    //                                      =:::.----::----:-=-----------=----=--=:-.   ::-==-=====-=          :--=---:.  .:.::. =                                  //    //
//    //                                        =::::---------::-:----=-=-==-=-==-======-===---==-==---------------::----:----:.-++                                   //    //
//    //                                         #=-::..:::--------::--::-----=--------:-=--=--===--====-=---=--------:---:-:..-=                                     //    //
//    //                                           #*==--::::----=------:-:--------==--==--=---:::----=----=-------:--:::-:.:--                                       //    //
//    //                                              *===---:::::-:-:----:-:----:-:::::-:-:--------=--=---:---::-:-:::------                                         //    //
//    //                                                 +*+=--::..:.:-:------:-:--:------:-:::-:--::--::--:-::-----.:---::                                           //    //
//    //                                                        .+:...:----:::-----:----:------::::--::::::-:::::::..--:                                              //    //
//    //                                                                  .---::::::::----------:--::--:::::--:::.::                                                  //    //
//    //                                                                       --===------:----------::-=--=::.                                                       //    //
//    //                                                                               *******+*++***                                                                 //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SAVE is ERC1155Creator {
    constructor() ERC1155Creator("SEASON 2 PreRelease by KAT KARTEL & OPTIC", "SAVE") {}
}

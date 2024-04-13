// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Casita de Cruz
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMWWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWWMMMMMMMMMMMM    //
//    MMMMMMMMMWXkocc::::::::::c:::::ccccccccccccccc::::::::::::::::::::::::::::;;;;;;;;;:::::;;;:::;;::::;;;;::::lxKWMMMMMMMM    //
//    MMMMMMMNkc'..':cclllc:,;lolc::coxxO000000Okkkkxddoccodl:::::;:::::::ccccc:::;,,,,,,;;:lc,,;;;:;,::::;'';cc:,...;kNMMMMMM    //
//    MMMMMMKc..,:lxOOkOkdc:;;cdOOxdxdk0XNWNNNNNNNXXKKK0Okxxollllllc::cloooodxdooxxo::;;;;;::::;coc;;:llllc;,:oool;'...:KMMMMM    //
//    MMMMMK; .:oxOO00K0o:;;;;;lkO0Okxk0XWNNNNNNNXXNNXXKXKOxddoooooolc;::cloxxxoodxdlc::;;;;;;;,,;oo;',:llc;,:lodo;,::. ;KMMMM    //
//    MMMMWo .;okOO0KOxdl;;;:;cx0kOK0dx0XNNXXNNNNNNNNNXKXX0OO00OOkkkxdolccclooooxkOkdoolc:::::;;,:lc;'.';lo:,:oolc;,:c;..dWMMM    //
//    MMMMN: .okkO00xlcol::llcloxxdOKOk0KXKKKXXNNXKKKXKKKK0000000OOOkkkOOOxdddddkOOkxkkOOOkdoolc:colc::;;lxl;coccc:,:c:. cNMMM    //
//    MMMMN: 'xOOOkoc:cddllllc::c:lxOOO00000000KKKKK00000000OkkkkkkkkOOO00000OkdoooddxkO000kxdxxxolcc::;:ooccllcll:;:c:. cNMMM    //
//    MMMMN: ,xOkxlc:;:dkolccllcc:cok000000OOO0KKKK0000OOkkxddxkkkkkkkkkkO0KKKKOdooooodxkOOxddxkkoc;,;cclc;;coddxoc;:c;. cNMMM    //
//    MMMMN: ,kkdlc:,,:x0OdlloolcccdkO0KK000K00KKKKKKKOxdoodxkkkkkkkxkkkkOO00Okkxdoooooooooodxxxxoc;;:lc:;,;:oxkkdc:::;. cNMMM    //
//    MMMMN: ,ddlc;,,,cxkkkdoodolllolld0K000OkkOKXK0OkdddkO000OkkxxxxxxkO00OkkkkOOkdollollllllllodxdollc;;;;:okOkoc:::;. cNMMM    //
//    MMMMN: 'loc:,;;:lxocclllloolc:::co0KKOkxddx00OO0OkOKXKK0OkxxdxxxoldkkkxxxO00Okkdoollccccccc:clloxdoc:;:dkkkoc::c;. cNMMM    //
//    MMMMN: .llc;;;;;cdocclc:cccc:::::cxKKKKOkdoxOO0K0O0KXXXK0Okxxxxxdl:ccloox000Okxdxkxdolcccc::clccodddoccoxxo::::c;. cNMMM    //
//    MMMMX: .cc:;;,;;collddlccclodolllcoOKK0xddoddddkO00KXXXXX0Oxdddddoolc::coxkOOxodxkkkxdddol;,;clccc;;::codoc;:::c:. cNMMM    //
//    MMMMN: .::;;:c::ldxdolcccdxxkkkOOxod0KK0kdddO0kkO00KXKK0kdooooodooxkxocclllloolodxdoodxkkxolol:;cloolc:clc:,::;:;. cNMMM    //
//    MMMMN: .;:;;col:okkkdlccccodxkk0KKOkk0XX0xdk0KKK0OO0KK0kdddxxxkxdokOxdxdlc::::::::;;;;cdxddxkxlclllloc::cc:,:c::;. cNMMM    //
//    MMMMN: .;:,;colcokkkkdlccccodxk0KKKXKKKKOkOKXXXK0kkkkxxxxkOkkkOxooxkxkO0kl;;;;;;;;;;;;;;:::lddolooc:;;:::cllodol:. cNMMM    //
//    MMMMN: .;:,;cc::oxkkkxollllodxO0KKXXXXXKKXXXKXXK0Okkkxdoollooddollodxxxxoc;col:;;;;;:::;;;;;;;::::cclc::lxkxolcc;. cNMMM    //
//    MMMMN: .::,,''':oxkkkkocclloxkk0KXXXXXXXXKKKXXXK0OO0KXK0Okdoolc:;;;;;;;;;;:lddolllc:codxdol:;;;;;;lkkoldkkdlllllc. cNMMM    //
//    MMMMN: .::,,,,;coxkxkkolllloxxk0K0KK0KKXKO0000K0Okxk0000OOOOkkxoc:;;;;;;;;;;;::cldxxoccclc:;;;;;;;lkxxxdooocooll:. cNMMM    //
//    MMMMN: .::;,:ccclxkxxxooddoldxkkOkxdxxkO0OOkkO00kddk0OOkkxxxdxkdlcool:;;;;col:;;;:::::;;cool;,;::;:lddlcool:ooc:;. cNMMM    //
//    MMMMN: .cl:;:::ldxxxxdlodxoldxkkkxxxkOxddxkxkO00xooxOkxxxdxxxxkxolllc::;;;;::;;;;;;col;cxOOoclllollc:::cllc:lo::,. cNMMM    //
//    MMMMN: .loc::codxxxxxdolodoldkkOkkxxxxdooodkOO00Okxddddxkxoc::;;;::c:,,,;;;;;;::cccodc;;ldoc:ccclol:,;:cllc:ll::,. cNMMM    //
//    MMMMN: .coc;:oddxxkkxddoodddxkkkxddxkxdoolcdkkkOOOOkddxko;'........'cl;',,,;;:ccllllcc:;;:cc;;;;;::,,;:cllc:lo::;. cNMMM    //
//    MMMMN: .coc::odxxxxkxdooddxxkkkxddxkxdoc;,cxkkkkkOOkxdo:;co:;'.;,....;o:,,,;::cloolllcccllc:ccccc:;,,;:cclc:loll:. cNMMM    //
//    MMMMN: .ldlcldxdddxkxdolodxkkkkxdxkkdolc;:xKKK0OOkkdccc,';'.  ..'.....lxl;:cclooodollccoxxocllcloc::;;:cclc;locc:. cNMMM    //
//    MMMMN: .oddddddxxddxdooodxxxxkkxxxxdoooodxxkxollccccccc,';,.  .'''',''cOOdlloddddolllcldxxocc:::c:::::ccllc;locc:. cNMMM    //
//    MMMMN: .ldddoxxxxdoooooodxddxxxxdxdlloddoodxddxkkkkxddoc;:c;,,:llll:;;cdk0Okkxdddlloloddoolc:;;::;;:::clllc;ll::;. cNMMM    //
//    MMMMN: .ldxddxxxxoolloooddddxxddoolccloooddxxk00000Okkxdlccllllllcc:clc:cdkKKOkdlclllodddolccccclc:::lolccc;lo::;. cNMMM    //
//    MMMMN: .oxdddxxdooodddollloodddddollollloodxxxxxxddxxxkkxdooollcccllll:;:ccoO00xc:ccccclolcllcllllccclolll:;ll::;. cNMMM    //
//    MMMMN: .ldddddolooodxxolllllloxxdooodxdoooddxxxxddooooooddddxxxddddddlcoddl:cxOOo::clllll:;:cc::cccccloccc:,cl;:;. cNMMM    //
//    MMMMN: .cdddlllddolloolloooolldxdoolldkkkxdlllccclllooooooooooooddxkOkdddxdc,:dkxc:cclol:,,;cc;;;::llooc::;,cc;:;. cNMMM    //
//    MMMMN: .cddolodxdoc:cc:::cclloxkkxdoodxkOOkxdollccccccccclloooollloloodddool:,cxkdlloolc;,,:llcc::clloo::::,cc;;,. cNMMM    //
//    MMMMN: .cdxdoddddoc:::cc:cccclxxxxxxxxxxddxkkkkdolllcccccccccccclllooooxxxxxo:;dOkxdolc:;,:llc:cllllcll::c:,cc;;,. cNMMM    //
//    MMMMN: .cdOxoddddoc::;::;::clooddxkkxxxddxkOOOkOOxollllllllcccccc::ccllooodolc:oOkxkxoc:;:lllc::cccccll::c:,cl;;,. cNMMM    //
//    MMMMN: .:dOkoddddoc::::::::cloooodxxxxxxxkOOOOdoxOkdolllllllllllccccccccllllllcoOkxO0Od:clllol::cccccll::c:,lo;,'. cNMMM    //
//    MMMMN: .:dOkodolll:;:c:cllllloddddddxxxxkkkxdolc:dOxolclllllllllllllooooooddooclkOOOOOkxollool::cllllol::c:,okc,'. cNMMM    //
//    MMMMN: .:dOkol:;:c:,,;:;;ccccllodxxxxdxkkxooodoc:oOxollcclllllllllllllooooooolccd0KKOOkkxolodoc;clodddl:;:;,okc,'. cNMMM    //
//    MMMMN: .:dOxc;,;:l:,,,;,,,;::ccccllodoodxdooxxdlccodolcccclodxkkxdoollloooooolcc:lk0Okkkkxollol:coxxdoolcl:;okc;,. cNMMM    //
//    MMMMN: .cdOd;;;;cl:,',;,,,:cloxxollccccclooxkxdolccoddolccclodxOOOkdoooooddddoooolcldddkkxdoddl::oxxxkkxxOOxoo:,,. cNMMM    //
//    MMMMN: .ldOd;;;;cl:,',;:;;:looxxddddoc::;;cdxxkkddoclxxdolclllloddddoddddddxxxxxkOkdoc:lddddddl;,cxkxdddxkkkd:,,,. cNMMM    //
//    MMMMN: .ldOd;;;:cl:;;:cc:;;:lodxdooooooc:;:odxxxxxoc:cdxdolccccllloooodddoloodddxkkkOkdolodxdoc:cdxollodxkkxo:;,,. cNMMM    //
//    MMMMN: .ldOd::::clcloolcc::::oddlllloddollodoolloolccooccccccccllllllooddolclllooodxkkkkxdooolcodoolc:looodo:,,,,. cNMMM    //
//    MMMMN: 'odxo:::cllodxollccc:;:coddoodxooddddolllcll:lddo:;coooolllllllodddolcccclllooodxxkxdolloolc::clllll:'.','. cNMMM    //
//    MMMMN: .ldocclcclloddoodlclc:;;ldddddoooooollllloolclxdoc;lO00kxdddolllooooocccccccllooodxdxxxollc:cllllloo;..'''. cNMMM    //
//    MMMMN: .cooodxxolloddddolclllc;cdxxddoooolooloodxdocoxdl:;ck00Oxooodolccccclllcc::::cclooooddkOdc;:lllllcll,.'','. cNMMM    //
//    MMMMN: 'odxkOkkkxoodxdlccclodo::ok0OO000OOOOkkkkxdocdkdl:;coxkkxdooddolcc:cccclllcc::;;:ccloxO0kc;:cllllll:...','. cNMMM    //
//    MMMMN: 'oxkOOkkkkxooxxdlclodxxllxO0OkOOOOO000OOOOkxooxoc::ccldxxxxxxxdollccccccccllllc:;,,codkOkd:;clllclc,..'',.  cNMMM    //
//    MMMMN: .,;;coddoxxxdloolccodxxddxdddddddxxddddxxxdddxoc::oxxdooxkOkxxdoolllcccclllllolc;'';odxkkkd::cllll;'.',,,'. cNMMM    //
//    MMMMN:  .'...,;:looddoooccloddoooddolloxkdodddodoodOkol::coddocoxxxxdooooolllllddloollc;,,,cddxkOkoclooo;...',,,'. cNMMM    //
//    MMMMN:  .......':lloxxxdlcoxkkxoloodolllollooooooodxdol:;:lllol:lddxddoooolllllollllll:;;:;;ldxkkkxllooc;;'..''''. cNMMM    //
//    MMMMN: .,.......;:lxkkkxddxkkkkxxxxxxxkxdollllllcodddol:;:looollc:lodddooolllllllllllc;:cc:,:odxxxxdllc::::'.''''. cNMMM    //
//    MMMMN: .c:;,'',:lllooooddddddddddddddxkkkkdoooolloddxoc;;cllllollc:clooooollllllllooc::cclc:;coddxxxlcc;,;:,','''. cNMMM    //
//    MMMMN: .ccccclccloollllllllloolloooodddooodddddolddool;;:lllllllllllcclloollllllllolcccllllc:;cdxxxxoc,';:;'',''.  cNMMM    //
//    MMMMN: .cc:::::cloollllllllllllcclcclllllc::cccllodolc;;cclllllllllllllcc:::ccclcclllllllllcc;;lodxko,.',,,.''...  cNMMM    //
//    MMMMN: .cc:;''',:c:::::::::::;,'',,'''''''..'';coxdolc:;::::::ccccclllllc:;,'',,,;:lllllllllllccloxOx;...,;'.''..  cNMMM    //
//    MMMMN: .c::;'''';cc::::::::::;,'',,,,,,,,;;clloxkxollllcll:,'''',,,;;;:::;,'.....',;;:loodollllloodO0c...........  cNMMM    //
//    MMMMN: .c::;;:::lollcllcccclccclllccccclodddollxkdooddlc:cl:;,''''.'''''''.........';:lllcclooodxxk00o.   .....''. cNMMM    //
//    MMMMN: .cc:;;:::lolcccccccclccloolcccllcccc:::okxooooddoc;;,,,,;::,',,,,,;::;;;;::ccc:;,;coddolloxkxddl,.......,'. cNMMM    //
//    MMMMN: .cc::;::cloollodddoloodddxdooollcccllclddlcddc::clllccclllc;,;;,'':llllc:;;,'...;ldol:;;:okx:.,coolooc'.,'. cNMMM    //
//    MMMMN: .cccolccloxxdxkxddxkkOOOkxxdddxkkxxxxdoc;,,:oo:,',,,;;;::;;;:::;;,,;:;,'...'',:lolc:,..':dkl.  .,oxdol,.,,. cNMMM    //
//    MMMMN: .:cloollloxkkxoodxkkkkkxxkkkkkOOOkxxxo:;;;::cllc;,;;;;::cccccc::::;,',;:::llolc:;,,,,''',oxo,...';::;,',;,. cNMMM    //
//    MMMMN: .;cloddddxkOxoodxkkkkkkxxkkkkkkkkkxdoolloooolllllccllllooooooolllllc;:looddoc:;;;;;;;;,;coxkd:,,;;;;;;:::;. cNMMM    //
//    MMMMN: .;ccldkkOOOOOOOkkkxddoooooooololoxxxddoooollclooolcclcllooooolllllll::lodoolccccccccc::odxOKKd;;:lolc::;;;. cNMMM    //
//    MMMMN: .'',;cllodkkkkkkkkxdollllllllcc::cllllccccccccllllllllllllllllllllllc::ccllcccccccccc::ldkO0kl;;clol:;;:c:. cNMMM    //
//    MMMMN: .'',,,'',:oddollllllccclllllllcccclcccccccccclllllllolllllllllllccccccccccccllclllllcc::clll::::cllc;,,,;,. cNMMM    //
//    MMMMN: .'''''',:lddollcc:::codxxxdoodddddddddddoooooooooodddddddddddoolllllllllllloooooollllllllclccccccclc;,,;;,. cNMMM    //
//    MMMMN: .'''''',;cllc:;;;:coxkkkkkxoloddooooooooolllllllloooooollllllcccccccccclllllllllcccccccccccccccc:clc,.',,,. cNMMM    //
//    MMMMN: ..''''''',:c:::::codxxxxxxdolllllllccccccccclllllllccccccccc:::cccccclloolllllcllllllllccccccccccllc;,;;;,. cNMMM    //
//    MMMMX: ..'''''''',;:ccccccdkO000K0Oxdlcccccc:;;:::::::cccccccc:::::::::ccclooooollllllllllcc::;;;;;;;:cllc:;;,;;;. cNMMM    //
//    MMMMNc .'''''....'',;:ccccoxOOOOOOkkxxxdollc:::::::::::ccccc::::cccc:::::cccccccc:::cccc:::;;;:;;;;:cllc;,'.',;;,. lWMMM    //
//    MMMMWd. .'''''''....',,;;;::::::cldxxxxxddoc;,',;;;;;;;;;;;;;;;::::;;,,,;;;;;;;;;;;;,;;;;,,,,,;;;;;cc:,....',,',. .kMMMM    //
//    MMMMMXc. .''',,,''..''''''''.....';::::cccccc;'...''''.......',,''......''''''''''''''''''''''''..''...''',,,.....oNMMMM    //
//    MMMMMMXd. ..';;;,'''''''.............',,,,,,,;;;'...'''..........................'''.................',,'',,'. .,kWMMMMM    //
//    MMMMMMMWKd;...........................',,,,'......  .....     ..  .......   ....      ..........   ..........,ckNMMMMMMM    //
//    MMMMMMMMMMWXOxdoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooodxkKNWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CDC is ERC1155Creator {
    constructor() ERC1155Creator("Casita de Cruz", "CDC") {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {TransparentUpgradeableProxy} from "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";

contract B3ASTS is TransparentUpgradeableProxy {
    constructor(address logic_, address admin_, bytes memory data_)
        TransparentUpgradeableProxy(logic_, admin_, data_)
    {}
}

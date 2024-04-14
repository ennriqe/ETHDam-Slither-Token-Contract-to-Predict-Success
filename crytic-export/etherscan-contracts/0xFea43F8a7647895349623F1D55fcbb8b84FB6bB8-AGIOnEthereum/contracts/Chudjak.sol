// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {UnibotLike} from "vendor/unibot/UnibotLike.sol";

contract AGIOnEthereum is UnibotLike {
    constructor() UnibotLike("AGI on Ethereum", "AGI",  10_000_000_000 * 1e18) {}
}
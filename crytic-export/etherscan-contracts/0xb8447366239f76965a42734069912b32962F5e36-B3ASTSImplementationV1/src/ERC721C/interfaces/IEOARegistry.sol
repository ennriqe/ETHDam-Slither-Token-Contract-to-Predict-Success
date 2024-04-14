// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";

interface IEOARegistry is IERC165 {
    function isVerifiedEOA(address account) external view returns (bool);
}

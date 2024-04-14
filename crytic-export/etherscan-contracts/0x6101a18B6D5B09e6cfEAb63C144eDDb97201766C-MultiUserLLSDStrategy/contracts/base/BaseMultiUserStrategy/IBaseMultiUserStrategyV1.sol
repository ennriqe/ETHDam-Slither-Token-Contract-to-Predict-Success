// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { ICoreUUPS_ABIVersionAware } from "../../core_upgradeable/ICoreUUPS_ABIVersionAware.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {
    IERC20MetadataUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IBaseMultiUserStrategyV1 is IERC20Upgradeable, IERC20MetadataUpgradeable, ICoreUUPS_ABIVersionAware {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {PropertiesAllo} from "./PropertiesAllo.t.sol";
import {PropertiesStrategies} from "./PropertiesStrategies.t.sol";

contract PropertiesParent is PropertiesAllo, PropertiesStrategies {}

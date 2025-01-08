// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {HandlerAllo} from "./HandlerAllo.t.sol";
import {HandlerRegistry} from "./HandlerRegistry.t.sol";
import {HandlerStrategy} from "./HandlerStrategy.t.sol";

contract HandlersParent is HandlerAllo, HandlerStrategy, HandlerRegistry {}

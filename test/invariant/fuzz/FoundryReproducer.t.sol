// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {FuzzTest} from "./FuzzTest.t.sol";
import {Actors} from "./Setup.t.sol";

contract FoundryReproducer is FuzzTest {
    function test_reproduce() public {
        assert(true);
    }
}

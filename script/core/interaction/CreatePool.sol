// SPDX-License-Identifier = MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";

import {Metadata} from "contracts/core/libraries/Metadata.sol";
import {Allo} from "contracts/core/Allo.sol";
import {IRegistry} from "contracts/core/interfaces/IRegistry.sol";

contract CreatePool is Script {
    // Define the following parameters for the new profile.
    uint256 public nonce = uint256(0);
    string public name = "";
    Metadata public metadata = Metadata({protocol: uint256(0), pointer: ""});
    address public owner = address(0);
    address[] public members = [];

    uint256 public msgValue = uint256(0);
    bytes32 public profileId = bytes32(0);
    address public strategy = address(0);
    bytes public initStrategyData = "";
    address public token = address(0);
    uint256 public amount = uint256(0);
    Metadata public metadata = Metadata({protocol: uint256(0), pointer: ""});
    address[] public managers;

    function run() public {
        vm.startBroadcast();
        bytes32 profileId = _createPool();
        vm.stopBroadcast();

        console.log("New profile created with id:");
        console.logBytes32(profileId);
    }

    function _createPool() internal returns (uint256 poolId) {
        Allo allo = Allo(vm.envAddress("ALLO_ADDRESS"));
        poolId =
            allo.createPool{value: msgValue}(profileId, strategy, initStrategyData, token, amount, metadata, managers);
    }
}

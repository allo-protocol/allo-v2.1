// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Utils} from "./Utils.t.sol";
import {Anchor} from "contracts/core/Anchor.sol";
import {GhostStorage} from "./GhostStorage.t.sol";

// Actors handler, reusing the msg.sender used by echidna (defined in the json)
// and tracking them, allowing to aggregate balances for instance.
//
// This tracks both anchors.
//
// This is handling the address making the call
// to the target contract, anchor are called by their owner only (for now?)
//
// For convenience, EOA used all have an anchor, used by default to call the end-target
contract Actors is Utils {
    event ActorsLog(string);

    address public controlledAnchor;

    function callThroughAnchor(
        address target,
        uint256 msgValue,
        bytes memory payload
    ) public returns (bool, bytes memory) {
        emit ActorsLog(
            string.concat("call using anchor of ", vm.toString(address(this)))
        );

        vm.deal(payable(address(this)), msgValue);

        (bool succ, bytes memory ret) = controlledAnchor.call{value: msgValue}(
            abi.encodeCall(Anchor.execute, (target, msgValue, payload))
        );

        if (!succ) {
            emit ActorsLog(vm.toString(ret));
            return (succ, ret);
        }

        if (ret.length != 0) {
            ret = abi.decode(ret, (bytes));
        }

        return (succ, ret);
    }

    function directCall(
        address target,
        uint256 msgValue,
        bytes memory payload
    ) public returns (bool success, bytes memory returnData) {
        emit ActorsLog(
            string.concat("call using actor ", vm.toString(address(this)))
        );

        vm.deal(payable(address(this)), msgValue);

        (success, returnData) = target.call{value: msgValue}(payload);
    }

    function changeAnchor(address newAnchor) public {
        controlledAnchor = newAnchor;
    }

    receive() external payable {}
}

contract HandlerActors is Utils, GhostStorage {
    function _currentActor() internal view returns (Actors _actor) {
        uint256 _seed = uint256(uint160(msg.sender));
        _actor = Actors(
            payable(_ghost_actors[(_seed % _ghost_actors.length) - 1])
        );
    }

    function _randomActor(uint256 _seed) internal view returns (Actors _actor) {
        _actor = Actors(payable(_ghost_actors[_seed % _ghost_actors.length]));
    }
}

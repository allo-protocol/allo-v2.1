// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Utils} from "./Utils.t.sol";
import {Anchor} from "contracts/core/Anchor.sol";

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
    address[] internal _ghost_actors = [
        address(0x10000),
        address(0x20000),
        address(0x30000),
        address(0x40000),
        address(0x50000),
        address(0x60000),
        address(0x70000),
        address(0x80000),
        address(0x90000),
        address(0xa0000)
    ];

    mapping(address actor => address anchor) internal _ghost_anchorOf;

    event ActorsLog(string);

    event Test(bytes);

    function targetCall(
        address target,
        uint256 msgValue,
        bytes memory payload
    ) internal returns (bool success, bytes memory returnData) {
        address anchorOwner = msg.sender;
        address anchor = _ghost_anchorOf[anchorOwner];

        if (anchor == address(0)) revert();

        emit ActorsLog(
            string.concat("call using anchor of ", vm.toString(anchorOwner))
        );

        vm.deal(payable(address(this)), msgValue);
        payable(anchorOwner).transfer(msgValue);

        vm.prank(anchorOwner);
        (success, returnData) = address(anchor).call{value: msgValue}(
            abi.encodeCall(Anchor.execute, (target, msgValue, payload))
        );

        returnData = abi.decode(returnData, (bytes));
    }

    function _addAnchorToActor(address _actor, address _anchor) internal {
        _ghost_anchorOf[_actor] = _anchor;
    }

    function _removeAnchorFromActor(
        address _actor,
        bytes32 _profileId
    ) internal {
        delete _ghost_anchorOf[_actor];
    }

    function _pickAnchor(uint256 _seed) internal view returns (address _actor) {
        _actor = _ghost_anchorOf[_ghost_actors[_seed % _ghost_actors.length]];
    }

    function _pickActor(uint256 _seed) internal view returns (address _actor) {
        _actor = _ghost_actors[_seed % _ghost_actors.length];
    }
}

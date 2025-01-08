// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Setup, Metadata, Actors} from "../Setup.t.sol";
import {IRegistry} from "contracts/core/Registry.sol";

contract HandlerRegistry is Setup {
    // create a new profile and discard it for now
    function handler_createProfile(uint256 _numberOfMembers) public {
        _numberOfMembers = bound(_numberOfMembers, 0, _ghost_actors.length);

        address[] memory _members = new address[](_numberOfMembers);
        for (uint256 i = 0; i < _numberOfMembers; i++) {
            _members[i] = _ghost_actors[i];
        }

        // Create a profile
        Actors _actor = _currentActor();
        (bool succ, bytes memory ret) = _actor.callThroughAnchor(
            address(registry),
            0,
            abi.encodeWithSelector(
                registry.createProfile.selector,
                ++_ghost_nonce,
                "",
                Metadata({protocol: _ghost_nonce, pointer: ""}),
                msg.sender,
                _members
            )
        );
    }

    function handler_updateProfileName(string memory _newName) public {
        // Get the profile ID
        Actors _actor = _currentActor();
        address _owner = address(_actor);

        IRegistry.Profile memory profile = registry.getProfileByAnchor(_actor.controlledAnchor());

        // will not succeed if no profile
        (bool succ, bytes memory ret) = _actor.callThroughAnchor(
            address(registry), 0, abi.encodeWithSelector(registry.updateProfileName.selector, profile.id, _newName)
        );

        if (succ) {
            _actor.changeAnchor(abi.decode(ret, (address)));
        }
    }

    function handler_updateProfileMetadata(uint256 _newProtocol, string memory _newPtr) public {
        Actors _actor = _currentActor();

        // Get the profile ID
        IRegistry.Profile memory profile = registry.getProfileByAnchor(_actor.controlledAnchor());

        (bool succ, bytes memory ret) = _actor.callThroughAnchor(
            address(registry),
            0,
            abi.encodeWithSelector(
                registry.updateProfileMetadata.selector,
                profile.id,
                Metadata({protocol: _newProtocol, pointer: _newPtr})
            )
        );
    }

    function handler_addMembers(uint256 _seed) public {
        Actors _actor = _currentActor();

        uint256 _memberToAdd = _seed % _ghost_actors.length;

        address[] memory _members = new address[](1);
        _members[0] = Actors(payable(_ghost_actors[_memberToAdd])).controlledAnchor();

        // Get the profile ID
        IRegistry.Profile memory profile = registry.getProfileByAnchor(_actor.controlledAnchor());

        (bool succ, bytes memory ret) = _actor.directCall(
            address(registry), 0, abi.encodeWithSelector(registry.addMembers.selector, profile.id, _members)
        );

        if (succ) {
            _ghost_roleMembers[profile.id].push(_members[0]);
        }
    }

    function handler_removeMembers(uint256 _seed) public {
        Actors _actor = _currentActor();

        // Get the profile ID
        IRegistry.Profile memory profile = registry.getProfileByAnchor(_actor.controlledAnchor());

        uint256 _membersToRemove = _seed % _ghost_roleMembers[profile.id].length;

        address[] memory _members = new address[](_membersToRemove);
        for (uint256 i = 0; i < _membersToRemove; i++) {
            _members[i] = _ghost_roleMembers[profile.id][i];
        }

        (bool succ, bytes memory ret) = _actor.callThroughAnchor(
            address(registry), 0, abi.encodeWithSelector(registry.removeMembers.selector, profile.id, _members)
        );

        // keep only the non-removed members in the ghost array
        if (succ) {
            address[] memory _nonRemovedMembers =
                new address[](_ghost_roleMembers[profile.id].length - _membersToRemove);

            for (uint256 i = 0; i < _nonRemovedMembers.length; i++) {
                _nonRemovedMembers[i] = _ghost_roleMembers[profile.id][i + _membersToRemove];
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Setup, Actors} from "../Setup.t.sol";
import {IRegistry} from "contracts/core/Registry.sol";
import {Allo, IAllo, Metadata, IBaseStrategy} from "contracts/core/Allo.sol";
import {FuzzERC20} from "../helpers/FuzzERC20.sol";

contract HandlerAllo is Setup {
    function handler_updatePoolMetadata(
        uint256 _idSeed,
        uint256 _metadataProtocol,
        string calldata _data
    ) public {
        // Needs at least one pool
        if (ghost_poolIds.length == 0) return;

        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);

        uint256 poolId = ghost_poolIds[_idSeed];

        // Get the profile ID
        IRegistry.Profile memory profile = registry.getProfileByAnchor(
            _currentActor().controlledAnchor()
        );

        // Avoid EOA
        if (profile.anchor == address(0)) return;

        Metadata memory metadata = Metadata({
            protocol: _metadataProtocol,
            pointer: _data
        });

        // Update the pool metadata - will revert on wrong anchor
        Actors _actor = _currentActor();

        _actor.callThroughAnchor(
            address(allo),
            0,
            abi.encodeCall(allo.updatePoolMetadata, (poolId, metadata))
        );
    }

    function handler_updatePercentFee(uint256 _newPercentFee) public {
        _newPercentFee = bound(_newPercentFee, 0, 1e18);

        // Update the percent fee - will revert if caller is not the owner
        Actors _actor = _currentActor();

        _actor.callThroughAnchor(
            address(allo),
            0,
            abi.encodeCall(allo.updatePercentFee, (_newPercentFee))
        );
    }

    function handler_updateBaseFee(uint256 _newBaseFee) public {
        // Update the base fee - will revert if caller is not the owner
        Actors _actor = _currentActor();

        _actor.callThroughAnchor(
            address(allo),
            0,
            abi.encodeCall(allo.updateBaseFee, (_newBaseFee))
        );
    }

    function handler_updateRegistry(address _newRegistry) public {
        // Update the registry - will revert if caller is not the owner or if the new registry is zero
        Actors _actor = _currentActor();

        _actor.callThroughAnchor(
            address(allo),
            0,
            abi.encodeCall(allo.updateRegistry, (_newRegistry))
        );
    }

    function handler_updateTreasury(address _newTreasury) public {
        // Update the treasury - will revert if caller is not the owner or if the new treasury is zero
        Actors _actor = _currentActor();

        _actor.callThroughAnchor(
            address(allo),
            0,
            abi.encodeCall(allo.updateTreasury, (payable(_newTreasury)))
        );
    }

    function handler_updateTrustedForwarder(address _newForwarder) public {
        // Update the trusted forwarder - will revert if caller is not the owner or if the new forwarder is zero
        Actors _actor = _currentActor();

        _actor.callThroughAnchor(
            address(allo),
            0,
            abi.encodeCall(Allo.updateTrustedForwarder, (_newForwarder))
        );
    }

    function handler_addPoolManagers(
        uint256 _idSeed,
        uint256 _numberOfManagers
    ) public {
        uint256 _poolId = _pickPoolId(_idSeed);
        _numberOfManagers = bound(_numberOfManagers, 0, _ghost_actors.length);

        // Gather the managers
        address[] memory _managers = new address[](_numberOfManagers);
        for (uint256 i; i < _numberOfManagers; i++) {
            _managers[i] = _ghost_actors[i];
        }

        // Add pool managers - will revert if caller is not the pool admin of the pool id
        Actors _actor = _currentActor();

        (bool _succ, ) = _actor.callThroughAnchor(
            address(allo),
            0,
            abi.encodeCall(allo.addPoolManagers, (_poolId, _managers))
        );

        if (_succ) {
            for (uint256 _i; _i < _managers.length; ++_i) {
                ghost_poolManagers[_poolId].push(_managers[_i]);
            }
        }
    }

    function handler_removePoolManagers(uint256 _idSeed) public {
        uint256 _poolId = _pickPoolId(_idSeed);
        address[] memory _managers = ghost_poolManagers[_poolId];

        // Remove pool managers - will revert if caller is not a pool admin of the pool id
        Actors _actor = _currentActor();

        (bool _succ, ) = _actor.callThroughAnchor(
            address(allo),
            0,
            abi.encodeCall(allo.removePoolManagers, (_poolId, _managers))
        );

        if (_succ) {
            delete ghost_poolManagers[_poolId];
        }
    }

    function handler_recoverFunds(address _recipient) public {
        // Recover funds - will revert if caller is not the owner
        Actors _actor = _currentActor();

        _actor.callThroughAnchor(
            address(allo),
            0,
            abi.encodeCall(allo.recoverFunds, (address(token), _recipient))
        );
    }

    function handler_registerRecipient(
        uint256 _idSeed,
        uint256 _numberOfRecipients,
        bytes memory _data,
        uint256 _msgValue
    ) public {
        uint256 _poolId = _pickPoolId(_idSeed);
        _numberOfRecipients = bound(
            _numberOfRecipients,
            0,
            _ghost_actors.length
        );

        // Gather the recipients
        address[] memory _recipientAddresses = new address[](
            _numberOfRecipients
        );
        for (uint256 i; i < _numberOfRecipients; i++) {
            _recipientAddresses[i] = _ghost_actors[i];
        }

        // Register recipient
        Actors _actor = _currentActor();

        (bool _succ, ) = _actor.callThroughAnchor(
            address(allo),
            _msgValue,
            abi.encodeCall(
                allo.registerRecipient,
                (_poolId, _recipientAddresses, _data)
            )
        );

        // todo: double-check there is no way a recipient is registered twice
        if (_succ) {
            for (uint256 i; i < _recipientAddresses.length; i++) {
                ghost_recipients[_poolId].push(_recipientAddresses[i]);
            }
        }
    }

    // function handler_fundPool(
    //     uint256 _idSeed,
    //     uint256 _amount,
    //     uint256 _msgValue
    // ) public {
    //     uint256 _poolId = _pickPoolId(_idSeed);
    //     uint256 _previousBalance = token.balanceOf(address(msg.sender));

    //     if (_previousBalance > 0) {
    //         _amount = bound(_amount, 0, type(uint256).max - _previousBalance);
    //     }

    //     if (_amount > 0) {
    //         FuzzERC20(address(token)).mint(address(msg.sender), _amount);
    //     }

    //     // Fund pool - will revert if the amount is zero or if pool token is native and message value is != amount
    //     Actors _actor = _currentActor();

    //     _actor.callThroughAnchor(
    //         address(allo),
    //         _msgValue,
    //         abi.encodeCall(allo.fundPool, (_poolId, _amount))
    //     );
    // }

    // // _seedAmounts at 50 as it is not likely we'll handle 50 actors at the same time (update if so)
    // function handler_allocate(
    //     uint256 _idSeed,
    //     uint256[50] memory _seedAmounts,
    //     bytes memory _data,
    //     uint256 _msgValue
    // ) public {
    //     uint256 _poolId = _pickPoolId(_idSeed);

    //     address[] memory _recipients = ghost_recipients[_poolId];
    //     uint256[] memory _amounts = new uint256[](_recipients.length);

    //     // Fund the allocator/sender
    //     for (uint256 i; i < _recipients.length; i++) {
    //         _amounts[i] = _seedAmounts[i];

    //         if (_amounts[i] > 0) {
    //             FuzzERC20(address(token)).mint(
    //                 address(msg.sender),
    //                 _amounts[i]
    //             );
    //         }
    //     }

    //     // Allocate - allocate to a recipient or multiple recipients
    //     Actors _actor = _currentActor();

    //     _actor.callThroughAnchor(
    //         address(allo),
    //         _msgValue,
    //         abi.encodeCall(
    //             allo.allocate,
    //             (_poolId, _recipients, _amounts, _data)
    //         )
    //     );
    // }

    // function handler_distribute(
    //     uint256 _idSeed,
    //     address[] memory _recipientIds,
    //     bytes memory _data
    // ) public {
    //     uint256 _poolId = _pickPoolId(_idSeed);

    //     // Distribute - distribute to a recipient or multiple recipients
    //     Actors _actor = _currentActor();

    //     _actor.callThroughAnchor(
    //         address(allo),
    //         0,
    //         abi.encodeCall(
    //             allo.distribute,
    //             (_poolId, ghost_recipients[_idSeed], _data)
    //         )
    //     );
    // }

    function handler_changeAdmin(uint256 _seed, uint256 _seedAdmin) public {
        uint256 _poolId = _pickPoolId(_seed);
        address _newAdmin = _ghost_actors[_seedAdmin % _ghost_actors.length];

        // Change admin - will revert if caller is not the pool admin
        Actors _actor = _currentActor();
        (bool success, ) = _actor.callThroughAnchor(
            address(allo),
            0,
            abi.encodeCall(allo.changeAdmin, (_poolId, _newAdmin))
        );
        if (success) {
            ghost_poolAdmins[_poolId] = _newAdmin;
            assertTrue(
                allo.isPoolAdmin(_poolId, _newAdmin),
                "Admin not set handler_changeAdmin"
            );
        }
    }

    function handler_createPoolWithCustomStrategy(uint256 _msgValue) internal {
        // Skipped for now
    }
}

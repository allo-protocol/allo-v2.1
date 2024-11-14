// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Utils} from "./Utils.t.sol";
import {Anchor} from "contracts/core/Anchor.sol";
import {Allo, IAllo} from "contracts/core/Allo.sol";

import {DirectAllocationStrategy} from "contracts/strategies/examples/direct-allocation/DirectAllocation.sol";
import {DonationVotingOnchain} from "contracts/strategies/examples/donation-voting/DonationVotingOnchain.sol";
import {EasyRPGF} from "contracts/strategies/examples/easy-rpgf/EasyRPGF.sol";
import {QVImpactStream} from "contracts/strategies/examples/impact-stream/QVImpactStream.sol";
import {QVSimple} from "contracts/strategies/examples/quadratic-voting/QVSimple.sol";
import {RFPSimple} from "contracts/strategies/examples/rfp/RFPSimple.sol";
import {SQFSuperfluid} from "contracts/strategies/examples/sqf-superfluid/SQFSuperfluid.sol";

import {Errors} from "contracts/core/libraries/Errors.sol";

import {IAllocationExtension} from "contracts/strategies/extensions/allocate/IAllocationExtension.sol";
import {IRecipientsExtension} from "contracts/strategies/extensions/register/IRecipientsExtension.sol";
import {IAllocatorsAllowlistExtension} from "contracts/strategies/extensions/allocate/IAllocatorsAllowlistExtension.sol";

contract Pools is Utils {
    Allo private allo;

    enum PoolStrategies {
        None,
        DirectAllocation,
        DonationVoting,
        EasyRPGF,
        ImpactStream,
        QuadraticVoting,
        RFP,
        SQFSuperfluid
    }

    uint256[] internal ghost_poolIds;
    mapping(uint256 _poolId => address _poolAdmin) internal ghost_poolAdmins;
    mapping(uint256 _poolId => address[] _managers) ghost_poolManagers;

    mapping(PoolStrategies _strategy => address _implementation)
        internal _strategyImplementations;

    //
    // Initializers
    //

    function _initImplementations(address _allo) internal {
        _strategyImplementations[PoolStrategies.DirectAllocation] = address(
            new DirectAllocationStrategy(_allo)
        );
        _strategyImplementations[PoolStrategies.DonationVoting] = address(
            new DonationVotingOnchain(_allo, "MyFancyName")
        );
        _strategyImplementations[PoolStrategies.EasyRPGF] = address(
            new EasyRPGF(_allo)
        );
        _strategyImplementations[PoolStrategies.ImpactStream] = address(
            new QVImpactStream(_allo)
        );
        _strategyImplementations[PoolStrategies.QuadraticVoting] = address(
            new QVSimple(_allo, "MyFancyName")
        );
        _strategyImplementations[PoolStrategies.RFP] = address(
            new RFPSimple(_allo)
        );
        _strategyImplementations[PoolStrategies.SQFSuperfluid] = address(
            new SQFSuperfluid(_allo)
        );

        allo = Allo(_allo);
    }

    function _recordPool(uint256 _poolId) internal {
        ghost_poolIds.push(_poolId);
    }

    //
    // Assertions helpers
    //

    // Check strategy dependent post-conditions if a call to allocate is successful
    function _assertValidAllocate(
        address _strategy,
        address _allocator
    ) internal {
        if (
            _poolStrategy(_strategy) == PoolStrategies.QuadraticVoting ||
            _poolStrategy(_strategy) == PoolStrategies.ImpactStream
        )
            assertTrue(
                IAllocatorsAllowlistExtension(address(_strategy))
                    .allowedAllocators(_allocator),
                "property-id 1-a: allocator not allowed"
            );
        else if (_poolStrategy(_strategy) == PoolStrategies.DonationVoting)
            assertTrue(
                IAllocationExtension(_strategy).allocationStartTime() <=
                    block.timestamp &&
                    IAllocationExtension(_strategy).allocationEndTime() >=
                    block.timestamp,
                "property-id 1-a: allocate outside of allocation window"
            );
    }

    function _assertInvalidAllocate(
        address _strategy,
        address _allocator,
        bytes memory _ret
    ) internal {
        if (
            _poolStrategy(_strategy) == PoolStrategies.QuadraticVoting ||
            _poolStrategy(_strategy) == PoolStrategies.ImpactStream
        )
            assertFalse(
                IAllocatorsAllowlistExtension(address(_strategy))
                    .allowedAllocators(_allocator),
                "property-id 1-a: allocator allowed but failed"
            );
        else if (
            _poolStrategy(_strategy) == PoolStrategies.RFP ||
            _poolStrategy(_strategy) == PoolStrategies.EasyRPGF
        )
            assertEq(
                abi.decode(_ret, (bytes4)),
                bytes4(Errors.NOT_IMPLEMENTED.selector),
                "property-id 1-a: wrong allocate() revert"
            ); // allocate not implemented
        else if (_poolStrategy(_strategy) == PoolStrategies.DonationVoting) {
            bytes4 _error = abi.decode(_ret, (bytes4));

            // Getter for recipient status is not implemented yet
            if (
                abi.decode(_ret, (bytes4)) !=
                bytes4(
                    IRecipientsExtension
                        .RecipientsExtension_RecipientNotAccepted
                        .selector
                )
            )
                assertTrue(
                    IAllocationExtension(_strategy).allocationStartTime() >
                        block.timestamp ||
                        IAllocationExtension(_strategy).allocationEndTime() <
                        block.timestamp
                );
        } else
            fail(
                "property-id 1-a: allocate call failed but should have succeeded"
            );
    }

    //
    // Getters
    //

    // reverse lookup pool id -> strategy type
    function _poolStrategy(uint256 _poolId) internal returns (PoolStrategies) {
        IAllo.Pool memory _pool = allo.getPool(_poolId);
        for (uint256 i = 1; i <= uint256(type(PoolStrategies).max); i++) {
            if (
                _strategyImplementations[PoolStrategies(i)] ==
                address(_pool.strategy)
            ) return PoolStrategies(i);
        }

        emit TestFailure("Wrong pool strategy implementation id");
    }

    // reverse lookup pool address -> strategy type
    function _poolStrategy(
        address _strategy
    ) internal returns (PoolStrategies) {
        for (uint256 i = 1; i <= uint256(type(PoolStrategies).max); i++) {
            if (_strategyImplementations[PoolStrategies(i)] == _strategy)
                return PoolStrategies(i);
        }

        emit TestFailure("Wrong pool strategy implementation address");
    }

    function _strategyHasImplementation(
        PoolStrategies _strategy
    ) internal returns (bool) {
        for (uint256 i; i < ghost_poolIds.length; i++) {
            if (_poolStrategy(ghost_poolIds[i]) == _strategy) return true;
        }

        return false;
    }

    function _pickPoolId(uint256 _idSeed) internal view returns (uint256) {
        if (ghost_poolIds.length == 0) return 0;

        return ghost_poolIds[_idSeed % ghost_poolIds.length];
    }

    function _pickPoolId(
        uint256[] memory _seeds
    ) internal view returns (uint256[] memory) {
        uint256[] memory _poolIds = new uint256[](_seeds.length);

        for (uint256 _i; _i < _seeds.length; ++_i) {
            _poolIds[_i] = _pickPoolId(_seeds[_i]);
        }

        return _poolIds;
    }

    function _isManager(
        address _sende,
        uint256 _poolId
    ) internal returns (bool __isManager) {
        for (uint256 _i; _i < ghost_poolManagers[_poolId].length; _i++) {
            if (msg.sender == ghost_poolManagers[_poolId][_i]) {
                __isManager = true;
                break;
            }
        }
    }
}

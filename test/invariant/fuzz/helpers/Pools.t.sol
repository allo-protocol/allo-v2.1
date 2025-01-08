// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Utils} from "./Utils.t.sol";
import {GhostStorage} from "./GhostStorage.t.sol";

import {Anchor} from "contracts/core/Anchor.sol";
import {Allo, IAllo, IBaseStrategy} from "contracts/core/Allo.sol";

import {DirectAllocationStrategy} from "contracts/strategies/examples/direct-allocation/DirectAllocation.sol";
import {DonationVotingOnchain} from "contracts/strategies/examples/donation-voting/DonationVotingOnchain.sol";
import {EasyRPGF} from "contracts/strategies/examples/easy-rpgf/EasyRPGF.sol";
import {QVImpactStream} from "contracts/strategies/examples/impact-stream/QVImpactStream.sol";
import {QVSimple} from "contracts/strategies/examples/quadratic-voting/QVSimple.sol";
import {RFPSimple} from "contracts/strategies/examples/rfp/RFPSimple.sol";
import {SQFSuperfluid} from "contracts/strategies/examples/sqf-superfluid/SQFSuperfluid.sol";

import {FuzzBaseStrategy} from "./FuzzBaseStrategy.t.sol";

import {Errors} from "contracts/core/libraries/Errors.sol";

import {IAllocationExtension} from "contracts/strategies/extensions/allocate/IAllocationExtension.sol";
import {IRecipientsExtension} from "contracts/strategies/extensions/register/IRecipientsExtension.sol";
import {IAllocatorsAllowlistExtension} from "contracts/strategies/extensions/allocate/IAllocatorsAllowlistExtension.sol";

contract Pools is Utils, GhostStorage {
    Allo private allo;

    enum PoolStrategies {
        FuzzBaseStrategy,
        DirectAllocation,
        DonationVoting,
        EasyRPGF,
        ImpactStream,
        QuadraticVoting,
        RFP,
        SQFSuperfluid
    }

    mapping(PoolStrategies _strategy => address _implementation)
        internal _strategyImplementations;

    //
    // Initializers
    //
    function _initImplementations(address _allo) internal {
        _strategyImplementations[PoolStrategies.FuzzBaseStrategy] = address(
            new FuzzBaseStrategy(_allo)
        );

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
    // Getters
    //
    function _aggregatePoolBalances()
        internal
        returns (uint256 _aggregateBalance)
    {
        // Cumulative sum based on the pool internal balances, we're assessing
        // its accuracy in a property (avoid "hiding" bad debt in unaccounted
        // tokens)
        uint256 _totalPoolBalances;
        for (uint256 i; i < ghost_poolIds.length; i++) {
            uint256 poolId = ghost_poolIds[i];

            _totalPoolBalances += IBaseStrategy(allo.getPool(poolId).strategy)
                .getPoolAmount();
        }
        return _totalPoolBalances;
    }

    function _totalAllocatedInPool(
        uint256 _poolId
    ) internal returns (uint256 _aggregateAllocation) {
        for (uint256 i; i < _ghost_actors.length; i++) {
            _aggregateAllocation += ghost_allocations[_poolId][
                _ghost_actors[i]
            ];
        }
    }

    // reverse lookup pool id -> strategy type
    function _poolStrategy(uint256 _poolId) internal returns (PoolStrategies) {
        IAllo.Pool memory _pool = allo.getPool(_poolId);
        for (uint256 i; i <= uint256(type(PoolStrategies).max); i++) {
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
        for (uint256 i; i <= uint256(type(PoolStrategies).max); i++) {
            if (_strategyImplementations[PoolStrategies(i)] == _strategy) {
                return PoolStrategies(i);
            }
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

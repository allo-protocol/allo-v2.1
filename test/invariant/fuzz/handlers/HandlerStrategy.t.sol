// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {HandlerAllo, IAllo} from "./HandlerAllo.t.sol";
import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";
import {Actors} from "../helpers/Actors.t.sol";

contract HandlerStrategy is HandlerAllo {
    mapping(uint256 _poolId => uint256 _amount) ghost_totalAllocated;
    mapping(uint256 _poolId => mapping(address _owner => uint256 _amount)) ghost_allocations;

    function handler_withdraw(uint256 _poolSeed, uint256 _amount) public {
        address _recipient = makeAddr("IAmRecipient");

        // Needs at least one pool
        if (ghost_poolIds.length == 0) return;

        // Get the pool
        _poolSeed = _poolSeed % ghost_poolIds.length;
        IAllo.Pool memory _pool = allo.getPool(ghost_poolIds[_poolSeed]);

        // Withdraw
        Actors _actor = _currentActor();
        (bool succ, ) = _actor.callThroughAnchor(
            address(_pool.strategy),
            0,
            abi.encodeCall(
                BaseStrategy.withdraw,
                (_pool.token, _amount, _recipient)
            )
        );
    }

    function handler_increasePoolAmount(
        uint256 _poolSeed,
        uint256 _amount
    ) public {
        _poolSeed = bound(_poolSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_poolSeed];

        // Needs at least one pool
        if (ghost_poolIds.length == 0) return;

        IAllo.Pool memory _pool = allo.getPool(ghost_poolIds[_poolSeed]);

        // Increase the pool amount
        Actors _actor = _currentActor();
        (bool succ, ) = _actor.callThroughAnchor(
            address(_pool.strategy),
            0,
            abi.encodeCall(BaseStrategy.increasePoolAmount, (_amount))
        );
    }
}

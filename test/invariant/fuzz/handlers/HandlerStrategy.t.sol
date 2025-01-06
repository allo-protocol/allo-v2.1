// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {HandlerAllo, IAllo} from "./HandlerAllo.t.sol";
import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";
import {Actors} from "../helpers/Actors.t.sol";
import {ERC20} from "../helpers/FuzzERC20.sol";

contract HandlerStrategy is HandlerAllo {
    function handler_directTokenTransfer(uint256 _poolSeed, uint256 _poolAmount, uint256 _amount) public {
        if (ghost_poolIds.length == 0) return;

        _poolSeed = _poolSeed % ghost_poolIds.length;
        IAllo.Pool memory _pool = allo.getPool(ghost_poolIds[_poolSeed]);

        ERC20(_pool.token).transfer(address(_pool.strategy), _amount);
    }

    function handler_withdraw(uint256 _poolSeed, uint256 _amount) public {
        address _recipient = makeAddr("IAmRecipient");

        // Needs at least one pool
        if (ghost_poolIds.length == 0) return;

        // Get the pool
        _poolSeed = _poolSeed % ghost_poolIds.length;
        IAllo.Pool memory _pool = allo.getPool(ghost_poolIds[_poolSeed]);

        // Withdraw
        Actors _actor = _currentActor();
        (bool succ,) = _actor.callThroughAnchor(
            address(_pool.strategy), 0, abi.encodeCall(BaseStrategy.withdraw, (_pool.token, _amount, _recipient))
        );
    }
}

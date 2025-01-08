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

        ghost_totalReceived += _amount;
    }
}

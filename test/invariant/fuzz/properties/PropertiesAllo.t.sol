// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Transfer} from "contracts/core/libraries/Transfer.sol";

import {HandlersParent} from "../handlers/HandlersParent.t.sol";
import {IAllo, Allo, Metadata} from "contracts/core/Allo.sol";
import {IRegistry, Registry} from "contracts/core/Registry.sol";
import {IBaseStrategy} from "contracts/strategies/BaseStrategy.sol";

import {Errors} from "contracts/core/libraries/Errors.sol";

import {FuzzERC20, ERC20} from "../helpers/FuzzERC20.sol";

contract PropertiesAllo is HandlersParent {
    ///@custom:property-id 4
    ///@custom:property Non-reversion: profile owner can always create a pool
    function prop_profileOwnerCanAlwaysCreateAPool(
        uint256 _msgValue,
        uint256 _anchorSeed
    ) public {
        IRegistry.Profile memory _profile = registry.getProfileByAnchor(
            _pickAnchor(_anchorSeed)
        );

        bool _isOwnerOrMember = registry.isOwnerOrMemberOfProfile(
            _profile.id,
            _ghost_anchorOf[msg.sender]
        );

        // Create a pool
        (bool succ, bytes memory ret) = targetCall(
            address(allo),
            _msgValue,
            abi.encodeCall(
                allo.createPool,
                (
                    _profile.id,
                    _strategyImplementations[PoolStrategies.DirectAllocation],
                    bytes(""),
                    address(token),
                    0,
                    _profile.metadata,
                    new address[](0)
                )
            )
        );

        // Revert if:
        // - the caller is not the owner or a member of the profile
        // - msg.value is not the baseFee
        // - the profile has no anchor
        if (!succ)
            assertTrue(
                _profile.anchor == address(0) ||
                    !_isOwnerOrMember ||
                    _msgValue != baseFee,
                "property-id 4: createPool failed"
            );
    }

    ///@custom:property-id 18
    ///@custom:property anyone can increase fund in a pool, if strategy (hook) logic allows so
    ///@dev This covers the case where the fees are 1e18 (ie 100% in fees)
    ///@custom:property-id 19
    ///@custom:property every deposit/pool creation must take the correct fee on the amount deposited, forwarded to the treasury
    function prop_anyoneCanIncreaseFundInAPool(
        uint256 _idSeed,
        uint256 _amount
    ) public {
        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];

        address _strategy = allo.getStrategy(_poolId);

        uint256 _feeAmount = (_amount * allo.getPercentFee()) /
            allo.getFeeDenominator();
        uint256 _amountAfterFee = _amount - _feeAmount;

        uint256 _previousBalanceStrategy;
        uint256 _previousBalanceTreasury;

        address _funder = _ghost_anchorOf[msg.sender];

        token.transfer(_funder, _amount);
        vm.prank(_funder);
        token.approve(address(allo), type(uint256).max);

        _previousBalanceStrategy = token.balanceOf(_strategy);
        _previousBalanceTreasury = token.balanceOf(treasury);

        (bool _success, ) = targetCall(
            address(allo),
            0,
            abi.encodeCall(allo.fundPool, (_poolId, _amount))
        );

        if (_success) {
            uint256 _afterBalanceStrategy;
            uint256 _afterBalanceTreasury;
            _afterBalanceStrategy = token.balanceOf(_strategy);
            _afterBalanceTreasury = token.balanceOf(treasury);
            assertEq(
                _afterBalanceStrategy,
                _previousBalanceStrategy + _amountAfterFee,
                "property-id 18: increasePoolFunds invalid strategy balance"
            );

            assertEq(
                _afterBalanceTreasury,
                _previousBalanceTreasury + _feeAmount,
                "property-id 19: increasePoolFunds invalid treasury balance"
            );

            ghost_totalReceived += _amountAfterFee;
            ghost_availableToAllocate += _amountAfterFee;
        } else {
            (
                bool _successAllocationEndtime,
                bytes memory _allocationEndTimedata
            ) = address(_strategy).call(
                    abi.encodeWithSignature("allocationEndTime()")
                );
            uint64 _allocationEndTime;
            if (_successAllocationEndtime) {
                _allocationEndTime = abi.decode(
                    _allocationEndTimedata,
                    (uint64)
                );
            }
            assertTrue(
                _amount == 0 ||
                    (_successAllocationEndtime &&
                        _allocationEndTime < block.timestamp) ||
                    _amount < allo.getPercentFee(),
                "property-id 18: increasePoolFunds failed"
            );
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Transfer} from "contracts/core/libraries/Transfer.sol";

import {HandlersParent} from "../handlers/HandlersParent.t.sol";
import {IAllo, Allo, Metadata} from "contracts/core/Allo.sol";
import {IRegistry, Registry} from "contracts/core/Registry.sol";
import {IBaseStrategy} from "contracts/strategies/BaseStrategy.sol";
import {IAllocationExtension} from "contracts/strategies/extensions/allocate/IAllocationExtension.sol";
import {RecipientsExtension, IRecipientsExtension} from "contracts/strategies/extensions/register/RecipientsExtension.sol";
import {IAllocatorsAllowlistExtension} from "contracts/strategies/extensions/allocate/IAllocatorsAllowlistExtension.sol";

import {Errors} from "contracts/core/libraries/Errors.sol";

import {FuzzERC20, ERC20} from "../helpers/FuzzERC20.sol";
import {FuzzBaseStrategy} from "../helpers/FuzzBaseStrategy.t.sol";
import {Actors} from "../helpers/Actors.t.sol";

contract PropertiesStrategies is HandlersParent {
    ///@custom:property-id ACC-1
    ///@custom:property Balance sheet is balanced / no bad debt
    function property_checkBalanceSheet() public {
        assertTrue(
            ghost_totalReceived ==
                ghost_availableToAllocate +
                    ghost_totalAllocatedNotDistributed +
                    ghost_totalWithdrawn,
            "Accounting: balance sheet inbalance"
        );
    }

    ///@custom:property-id ACC-2
    ///@custom:property Each pool internal balance is consistent with its real balance
    function property_checkPoolSolvability() public {
        for (uint256 i; i < ghost_poolIds.length; i++) {
            uint256 poolId = ghost_poolIds[i];
            uint256 poolReportedBalance = allo
                .getPool(poolId)
                .strategy
                .getPoolAmount();

            uint256 poolObservedBalance = token.balanceOf(
                address(allo.getPool(poolId).strategy)
            );

            // gte as we have a handler for token direct transfer to the pool
            assertTrue(
                poolObservedBalance >= poolReportedBalance,
                "Accounting: pool internal insolvability"
            );
        }
    }

    ///@custom:property-id 1
    ///@custom:property manager should be able to allocate for recipient (based on strategy)
    function prop_userShouldBeAbleToAllocateForRecipient(
        uint256 _actorSeed,
        uint256 _idSeed,
        uint256 _amount
    ) public {
        Actors _actor = _currentActor();
        address _allocator = _currentActor().controlledAnchor();

        address _recipient = address(_randomActor(_actorSeed));

        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);

        address[] memory _recipients = new address[](1);
        _recipients[0] = _recipient;

        address[] memory _tokens = new address[](1);
        _tokens[0] = address(token);

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = _amount;

        uint256 _poolId = ghost_poolIds[_idSeed];

        address _strategy = address(allo.getPool(_poolId).strategy);

        // DV needs the token in _data
        bytes memory _data = _poolStrategy(_strategy) ==
            PoolStrategies.DonationVoting
            ? abi.encode(token, new bytes(0))
            : abi.encode(_tokens);

        // Needed for direct allocation
        token.transfer(_allocator, _amount);
        _actor.callThroughAnchor(
            address(token),
            0,
            abi.encodeCall(ERC20.approve, (address(_strategy), _amount))
        );

        (bool _success, bytes memory _ret) = _actor.callThroughAnchor(
            address(allo),
            0,
            abi.encodeCall(
                allo.allocate,
                (_poolId, _recipients, _amounts, _data)
            )
        );

        if (_success) {
            // Check strategy specific post-conditions
            _assertValidAllocate(
                payable(_strategy),
                _allocator,
                _recipient,
                _amount
            );

            ghost_totalAllocatedNotDistributed += _amount;

            if (_poolStrategy(_strategy) != PoolStrategies.DirectAllocation) {
                ghost_allocations[_poolId][address(_recipient)] += _amount;
            } else {
                // allocation is directly distributed
                ghost_totalAllocatedNotDistributed -= _amount;
                ghost_totalWithdrawn += _amount;
            }

            ghost_availableToAllocate -= _amount;
            ghost_allocations[_poolId][_recipient] += _amount;
        } else {
            _assertInvalidAllocate(_strategy, _allocator, _ret);
        }
    }

    ///@custom:property-id 2
    ///@custom:property manager should be able to distribute correct (based on strategy) allocation for recipient
    function prop_poolManagerShouldBeAbleToDistributeToRecipient(
        uint256 _idSeed,
        uint256 _managerSeed,
        uint256 _actorSeed,
        uint256 _amount
    ) public {
        address _recipient = address(_currentActor());
        address[] memory _recipients = new address[](1);
        _recipients[0] = _recipient;

        bytes memory _data = new bytes(0);

        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];

        address _manager = ghost_poolManagers[_poolId][
            (_managerSeed % ghost_poolManagers[_poolId].length)
        ];

        IBaseStrategy _strategy = allo.getPool(_poolId).strategy;

        bool _hasAllocation = ghost_allocations[_poolId][_recipient] > 0;
        uint256 _recipientPreviousBalance = token.balanceOf(_recipient);
        uint256 _poolAmount = _strategy.getPoolAmount();

        vm.prank(_manager);
        (bool _success, bytes memory _ret) = address(allo).call(
            abi.encodeCall(allo.distribute, (_poolId, _recipients, _data))
        );

        // General (non-)revertion assertion, should be common to all strategies
        if (_success) {
            uint256 _recipientNewBalance = token.balanceOf(_recipient);

            // Allocation if there is one
            assertTrue(
                _hasAllocation,
                "property-id 3: Distribution succeeded without allocation"
            );

            ghost_totalAllocatedNotDistributed -= _amount;
            ghost_totalWithdrawn += _amount;
        } else {
            // Revert if:
            // - There is no allocation
            // - There is not enough token to cover the allocation
            // - allocate() is not implemented by the strategy
            assertTrue(
                !_hasAllocation ||
                    _totalAllocatedInPool(_poolId) > _poolAmount ||
                    abi.decode(_ret, (bytes4)) ==
                    Errors.NOT_IMPLEMENTED.selector,
                "property-id 3: Distribution failed while allocation should be valid"
            );
        }
    }

    ///@custom:property-id 3
    ///@custom:property only funds outside the poolAmount can be withdrawn from a pool
    function prop_onlyUnallocatedWithdrawable(
        uint256 _poolSeed,
        uint256 _amount
    ) public {
        uint256 _poolId = _pickPoolId(_poolSeed);
        address _strategy = allo.getStrategy(_poolId);
        address _manager = ghost_poolManagers[_poolId][0];

        uint256 poolActualBalance = token.balanceOf(_strategy);
        uint256 poolInternalBalance = allo
            .getPool(_poolId)
            .strategy
            .getPoolAmount();

        Actors _actor = _currentActor();
        (bool success, ) = _actor.callThroughAnchor(
            address(_strategy),
            0,
            abi.encodeCall(
                IBaseStrategy.withdraw,
                (address(token), _amount, msg.sender)
            )
        );

        if (success) {
            assertTrue(
                _actor.controlledAnchor() == _manager,
                "property-id 3: Caller not manager"
            );

            assertTrue(
                _amount <= poolActualBalance - poolInternalBalance,
                "property-id 3: Withdrew allocated funds"
            );
        } else {
            assertTrue(
                _actor.controlledAnchor() != _manager ||
                    _amount > poolActualBalance - poolInternalBalance,
                "property-id 3: Withdraw failed"
            );
        }
    }

    //
    // Assertions helpers
    //

    // Check strategy dependent post-conditions if a call to allocate is successful
    function _assertValidAllocate(
        address payable _strategy,
        address _allocator,
        address _recipient,
        uint256 _amount
    ) internal {
        if (
            _poolStrategy(_strategy) == PoolStrategies.QuadraticVoting ||
            _poolStrategy(_strategy) == PoolStrategies.ImpactStream
        ) {
            assertTrue(
                IAllocatorsAllowlistExtension(address(_strategy))
                    .allowedAllocators(_allocator),
                "property-id 1 QV/IS: allocator not allowed"
            );
        } else if (_poolStrategy(_strategy) == PoolStrategies.DonationVoting) {
            assertTrue(
                IAllocationExtension(_strategy).allocationStartTime() <=
                    block.timestamp &&
                    IAllocationExtension(_strategy).allocationEndTime() >=
                    block.timestamp,
                "property-id 1 DV: allocate outside of allocation window"
            );
        } else if (
            _poolStrategy(_strategy) == PoolStrategies.FuzzBaseStrategy
        ) {
            assertTrue(
                FuzzBaseStrategy(_strategy).allocated(_recipient) == _amount,
                "property-id 1 Fuzz: wrong amount allocated"
            );
        } else if (
            _poolStrategy(_strategy) == PoolStrategies.DirectAllocation
        ) {
            // Empty
        } else {
            fail(
                "property-id 1: allocate call succeeded but should have failed"
            );
        }
    }

    function _assertInvalidAllocate(
        address _strategy,
        address _allocator,
        bytes memory _ret
    ) internal {
        if (
            _poolStrategy(_strategy) == PoolStrategies.QuadraticVoting ||
            _poolStrategy(_strategy) == PoolStrategies.ImpactStream
        ) {
            assertFalse(
                IAllocatorsAllowlistExtension(address(_strategy))
                    .allowedAllocators(_allocator),
                "property-id 2 QV/IS: allocator allowed but failed"
            );
        } else if (
            _poolStrategy(_strategy) == PoolStrategies.RFP ||
            _poolStrategy(_strategy) == PoolStrategies.EasyRPGF
        ) {
            assertEq(
                abi.decode(_ret, (bytes4)),
                bytes4(Errors.NOT_IMPLEMENTED.selector),
                "property-id 2 RFP/RPGF: wrong allocate() revert"
            );
        }
        // allocate not implemented
        else if (_poolStrategy(_strategy) == PoolStrategies.DonationVoting) {
            bytes4 _error = abi.decode(_ret, (bytes4));

            // Getter for recipient status is not implemented (yet?)
            if (
                abi.decode(_ret, (bytes4)) !=
                bytes4(
                    IRecipientsExtension
                        .RecipientsExtension_RecipientNotAccepted
                        .selector
                )
            ) {
                assertTrue(
                    IAllocationExtension(_strategy).allocationStartTime() >
                        block.timestamp ||
                        IAllocationExtension(_strategy).allocationEndTime() <
                        block.timestamp,
                    "property 2 DV: Allocation failed in correct period"
                );
            }
        } else if (
            _poolStrategy(_strategy) == PoolStrategies.FuzzBaseStrategy
        ) {
            assertTrue(
                !_isManager(_allocator, IBaseStrategy(_strategy).getPoolId()),
                "property-id 2: wrong allocate() revert for FuzzBaseStrategy"
            );
        } else {
            fail(
                "property-id 2: allocate call failed but should have succeeded"
            );
        }
    }
}

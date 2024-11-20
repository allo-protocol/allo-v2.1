// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.19;
// import {Transfer} from "contracts/core/libraries/Transfer.sol";

// import {HandlersParent} from "../handlers/HandlersParent.t.sol";
// import {IAllo, Allo, Metadata} from "contracts/core/Allo.sol";
// import {IRegistry, Registry} from "contracts/core/Registry.sol";
// import {IBaseStrategy} from "contracts/strategies/BaseStrategy.sol";

// import {Errors} from "contracts/core/libraries/Errors.sol";

// import {FuzzERC20, ERC20} from "../helpers/FuzzERC20.sol";

// contract PropertiesAllo is HandlersParent {
//     ///@custom:property-id 1-a
//     ///@custom:property one should always be able to allocate for recipient
//     function prop_userShouldBeAbleToAllocateForRecipient(
//         uint256 _actorSeed,
//         uint256 _idSeed,
//         uint256 _amount
//     ) public {
//         address _recipient = _pickAnchor(_actorSeed);

//         _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
//         uint256 _poolId = ghost_poolIds[_idSeed];

//         address _strategy = address(allo.getPool(_poolId).strategy);
//         bytes32 _strategyId = allo.getPool(_poolId).strategy.getStrategyId();

//         address[] memory _recipients = new address[](1);
//         _recipients[0] = _recipient;

//         address[] memory _tokens = new address[](1);
//         _tokens[0] = address(token);

//         uint256[] memory _amounts = new uint256[](1);
//         _amounts[0] = _amount;

//         bytes memory _data = _poolStrategy(_strategy) ==
//             PoolStrategies.DonationVoting
//             ? abi.encode(token, new bytes(0))
//             : abi.encode(_tokens);

//         address _allocator = _ghost_anchorOf[msg.sender];

//         uint256 _recipientPreviousBalance;

//         token.transfer(_allocator, _amount);
//         vm.prank(_allocator);
//         token.approve(_strategy, _amount);
//         _recipientPreviousBalance = token.balanceOf(_recipient);

//         (bool _success, bytes memory _ret) = targetCall(
//             address(allo),
//             0,
//             abi.encodeCall(
//                 allo.allocate,
//                 (_poolId, _recipients, _amounts, _data)
//             )
//         );

//         if (_success) {
//             assertEq(
//                 token.balanceOf(_recipient),
//                 _allocator == _recipient
//                     ? _recipientPreviousBalance
//                     : _recipientPreviousBalance + _amount,
//                 "property-id 1-a: wrong balancer after allocation"
//             );

//             // Check strategy specific post-conditions
//             _assertValidAllocate(_strategy, _allocator);

//             if (_poolStrategy(_strategy) != PoolStrategies.DirectAllocation)
//                 ghost_allocation[_poolId][_recipient] += _amount;
//         } else {
//             _assertInvalidAllocate(_strategy, _allocator, _ret);
//         }
//     }

//     ///@custom:property-id 1-b
//     ///@custom:property one should always be able to pull correct (based on strategy) allocation for recipient
//     ///TODO: For now, this is only handling direct allocation (which has now allocation/distribution)
//     function prop_poolManagerShouldBeAbleToDistributeToRecipient(
//         uint256 _idSeed,
//         uint256 _managerSeed,
//         uint256 _actorSeed,
//         uint256 _amount
//     ) public {
//         address _recipient = _pickAnchor(_actorSeed);

//         address[] memory _recipients = new address[](1);
//         _recipients[0] = _recipient;

//         bytes memory _data = new bytes(0);

//         _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
//         uint256 _poolId = ghost_poolIds[_idSeed];

//         address _manager = ghost_poolManagers[_poolId][
//             (_managerSeed % ghost_poolManagers[_poolId].length) - 1
//         ];

//         IBaseStrategy _strategy = allo.getPool(_poolId).strategy;

//         // Direct allocation only in this contract
//         if (
//             _strategy.getStrategyId() !=
//             keccak256(abi.encode("DirectAllocation"))
//         ) {
//             return;
//         }

//         uint256 _recipientPreviousBalance = token.balanceOf(_recipient);

//         token.transfer(address(_strategy), _amount);
//         uint256 _poolAmount = _strategy.getPoolAmount();

//         vm.prank(_manager);
//         (bool _success, bytes memory _ret) = address(allo).call(
//             abi.encodeCall(allo.distribute, (_poolId, _recipients, _data))
//         );

//         if (_success) {
//             assert(false); // Should not reach here
//         } else {
//             assertEq(
//                 abi.decode(_ret, (bytes4)),
//                 Errors.NOT_IMPLEMENTED.selector,
//                 "property-id 1-b: distribute failed with correct amounts"
//             );
//         }
//     }

//     ///@custom:property-id 2
//     ///@custom:property a token allocation never “disappears” (withdraw cannot impact an allocation)
//     function prop_allocationPersists(
//         uint256 _poolSeed,
//         uint256 _withdrawAmount
//     ) public {
//         uint256 _poolId = _pickPoolId(_poolSeed);
//         address _strategy = allo.getStrategy(_poolId);

//         // Track pre-withdrawal allocations
//         uint256[] memory preAllocations = new uint256[](
//             ghost_recipients[_poolId].length
//         );
//         for (uint256 i = 0; i < ghost_recipients[_poolId].length; i++) {
//             preAllocations[i] = ghost_allocations[_poolId][
//                 ghost_recipients[_poolId][i]
//             ];
//         }

//         // Execute withdrawal
//         (bool success, ) = targetCall(
//             address(_strategy),
//             0,
//             abi.encodeCall(
//                 IBaseStrategy.withdraw,
//                 (address(token), _withdrawAmount, msg.sender)
//             )
//         );

//         if (success) {
//             // Verify allocations unchanged
//             for (uint256 i = 0; i < ghost_recipients[_poolId].length; i++) {
//                 assertEq(
//                     ghost_allocations[_poolId][ghost_recipients[_poolId][i]],
//                     preAllocations[i],
//                     "property-id 2: Allocation changed after withdrawal"
//                 );
//             }
//         } else {
//             assertEq(
//                 _poolStrategy(_strategy),
//                 PoolStrategies.DirectAllocation,
//                 "Property 2: Withdraw failed"
//             );
//         }
//     }

//     ///@custom:property-id 3
//     ///@custom:property an address can only distribute if has allocation
//     function prop_distributionRequiresAllocation(
//         uint256 _poolSeed,
//         uint256 _actorSeed,
//         uint256 _amount
//     ) public {
//         address _recipient = _pickAnchor(_actorSeed);

//         address[] memory _recipients = new address[](1);
//         _recipients[0] = _recipient;

//         bytes memory _data = new bytes(0);

//         _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
//         uint256 _poolId = ghost_poolIds[_idSeed];

//         address _manager = ghost_poolManagers[_poolId][
//             (_managerSeed % ghost_poolManagers[_poolId].length) - 1
//         ];

//         IBaseStrategy _strategy = allo.getPool(_poolId).strategy;

//         bool hasAllocation = ghost_allocations[_poolId][msg.sender] > 0;

//         // Direct allocation only in this contract
//         if (
//             _strategy.getStrategyId() !=
//             keccak256(abi.encode("DirectAllocation"))
//         ) {
//             return;
//         }

//         uint256 _recipientPreviousBalance = token.balanceOf(_recipient);

//         token.transfer(address(_strategy), _amount);
//         uint256 _poolAmount = _strategy.getPoolAmount();

//         vm.prank(_manager);
//         (bool _success, bytes memory _ret) = address(allo).call(
//             abi.encodeCall(allo.distribute, (_poolId, _recipients, _data))
//         );

//         if (_success) {
//             assertTrue(
//                 hasAllocation,
//                 "property-id 3: Withdrawal succeeded without allocation"
//             );
//         } else {
//             assertTrue(
//                 !hasAllocation ||
//                     _poolStrategy(_strategy) == PoolStrategies.DirectAllocation,
//                 "property-id 3: Withdrawal failed while allocation"
//             );
//         }
//     }

//     ///@custom:property-id 12
//     ///@custom:property pool manager can always withdraw within strategy limits/logic
//     function prop_managerWithdrawalWithinLimits(
//         uint256 _poolSeed,
//         uint256 _amount
//     ) public {
//         uint256 _poolId = _pickPoolId(_poolSeed);
//         address _strategy = allo.getStrategy(_poolId);

//         if (!allo.isPoolManager(_poolId, msg.sender)) return;

//         uint256 withdrawableAmount = token.balanceOf(_strategy) -
//             ghost_totalAllocated[_poolId];

//         (bool success, ) = targetCall(
//             address(_strategy),
//             0,
//             abi.encodeCall(
//                 IBaseStrategy.withdraw,
//                 (address(token), _amount, msg.sender)
//             )
//         );

//         if (success) {
//             assertLe(
//                 _amount,
//                 withdrawableAmount,
//                 "property-id 12: Withdrawal exceeded unallocated amount"
//             );
//         }
//     }

//     ///@custom:property-id 17
//     ///@custom:property only funds not allocated can be withdrawn
//     function prop_onlyUnallocatedWithdrawable(
//         uint256 _poolSeed,
//         uint256 _amount
//     ) public {
//         uint256 _poolId = _pickPoolId(_poolSeed);
//         address _strategy = allo.getStrategy(_poolId);

//         uint256 totalAllocated = ghost_totalAllocated[_poolId];
//         uint256 poolBalance = token.balanceOf(_strategy);

//         (bool success, ) = targetCall(
//             address(_strategy),
//             0,
//             abi.encodeCall(
//                 IBaseStrategy.withdraw,
//                 (address(token), _amount, msg.sender)
//             )
//         );

//         if (success) {
//             assertTrue(
//                 _amount <= poolBalance - totalAllocated,
//                 "property-id 17: Withdrew allocated funds"
//             );
//         }
//     }

//     ///@custom:property-id 18
//     ///@custom:property anyone can increase fund in a pool, if strategy (hook) logic allows so and if more than base fee
//     function prop_canIncreaseFunds(uint256 _poolSeed, uint256 _amount) public {
//         uint256 _poolId = _pickPoolId(_poolSeed);
//         address _strategy = allo.getStrategy(_poolId);

//         uint256 preFunding = token.balanceOf(_strategy);

//         (bool success, ) = targetCall(
//             address(allo),
//             0,
//             abi.encodeCall(IAllo.fundPool, (_poolId, _amount))
//         );

//         if (success) {
//             assertGt(
//                 token.balanceOf(_strategy),
//                 preFunding,
//                 "property-id 18: Pool funding not increased"
//             );

//             // Ensure base fee was paid
//             assertTrue(
//                 _amount >= allo.getBaseFee(),
//                 "property-id 18: Funding below base fee"
//             );

//             // Check strategy hooks allowed
//             assertTrue(
//                 _allowedByStrategyHooks(_strategy),
//                 "property-id 18: Strategy hooks rejected funding"
//             );
//         }
//     }

//     //
//     // Assertions helpers
//     //

//     // Check strategy dependent post-conditions if a call to allocate is successful
//     function _assertValidAllocate(
//         address _strategy,
//         address _allocator
//     ) internal {
//         if (
//             _poolStrategy(_strategy) == PoolStrategies.QuadraticVoting ||
//             _poolStrategy(_strategy) == PoolStrategies.ImpactStream
//         )
//             assertTrue(
//                 IAllocatorsAllowlistExtension(address(_strategy))
//                     .allowedAllocators(_allocator),
//                 "property-id 1-a: allocator not allowed"
//             );
//         else if (_poolStrategy(_strategy) == PoolStrategies.DonationVoting)
//             assertTrue(
//                 IAllocationExtension(_strategy).allocationStartTime() <=
//                     block.timestamp &&
//                     IAllocationExtension(_strategy).allocationEndTime() >=
//                     block.timestamp,
//                 "property-id 1-a: allocate outside of allocation window"
//             );
//     }

//     function _assertInvalidAllocate(
//         address _strategy,
//         address _allocator,
//         bytes memory _ret
//     ) internal {
//         if (
//             _poolStrategy(_strategy) == PoolStrategies.QuadraticVoting ||
//             _poolStrategy(_strategy) == PoolStrategies.ImpactStream
//         )
//             assertFalse(
//                 IAllocatorsAllowlistExtension(address(_strategy))
//                     .allowedAllocators(_allocator),
//                 "property-id 1-a: allocator allowed but failed"
//             );
//         else if (
//             _poolStrategy(_strategy) == PoolStrategies.RFP ||
//             _poolStrategy(_strategy) == PoolStrategies.EasyRPGF
//         )
//             assertEq(
//                 abi.decode(_ret, (bytes4)),
//                 bytes4(Errors.NOT_IMPLEMENTED.selector),
//                 "property-id 1-a: wrong allocate() revert"
//             ); // allocate not implemented
//         else if (_poolStrategy(_strategy) == PoolStrategies.DonationVoting) {
//             bytes4 _error = abi.decode(_ret, (bytes4));

//             // Getter for recipient status is not implemented yet
//             if (
//                 abi.decode(_ret, (bytes4)) !=
//                 bytes4(
//                     IRecipientsExtension
//                         .RecipientsExtension_RecipientNotAccepted
//                         .selector
//                 )
//             )
//                 assertTrue(
//                     IAllocationExtension(_strategy).allocationStartTime() >
//                         block.timestamp ||
//                         IAllocationExtension(_strategy).allocationEndTime() <
//                         block.timestamp
//                 );
//         } else
//             fail(
//                 "property-id 1-a: allocate call failed but should have succeeded"
//             );
//     }

//     function _allowedByStrategyHooks(
//         address _strategy
//     ) internal view returns (bool) {
//         if (_poolStrategy(_strategy) == PoolStrategies.RFP) {
//             return block.timestamp <= allocationEndTime;
//         } else if (_poolStrategy(_strategy) == PoolStrategies.DonationVoting) {
//             return !ghost_distributionStarted[_poolId];
//         }
//         return true;
//     }
// }

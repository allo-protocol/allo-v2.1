// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockMockBaseStrategy} from "test/smock/MockMockBaseStrategy.sol";
import {IBaseStrategy} from "strategies/IBaseStrategy.sol";

contract BaseStrategy is Test {
    MockMockBaseStrategy baseStrategy;

    function setUp() public {
        baseStrategy = new MockMockBaseStrategy(address(0));
    }

    function test___BaseStrategy_initShouldCallOnlyAllo(uint256 _poolId) external {
        vm.assume(_poolId != 0);
        baseStrategy.mock_call__checkOnlyAllo();

        // It should call onlyAllo
        baseStrategy.expectCall__checkOnlyAllo();

        baseStrategy.call___BaseStrategy_init(_poolId);
    }

    function test___BaseStrategy_initRevertWhen_PoolIdIsZero(uint256 _currentPoolId, uint256 _poolId) external {
        vm.assume(_currentPoolId != 0);
        baseStrategy.mock_call__checkOnlyAllo();

        baseStrategy.set__poolId(_currentPoolId);

        // It should revert
        vm.expectRevert(IBaseStrategy.BaseStrategy_ALREADY_INITIALIZED.selector);

        baseStrategy.call___BaseStrategy_init(_poolId);
    }

    function test___BaseStrategy_initRevertWhen_PoolIdArgumentIsZero() external {
        baseStrategy.mock_call__checkOnlyAllo();

        // It should revert
        vm.expectRevert(IBaseStrategy.BaseStrategy_INVALID_POOL_ID.selector);

        baseStrategy.call___BaseStrategy_init(0);
    }

    function test___BaseStrategy_initShouldSetPoolId(uint256 _poolId) external {
        vm.assume(_poolId != 0);
        baseStrategy.mock_call__checkOnlyAllo();

        baseStrategy.call___BaseStrategy_init(_poolId);

        // It should set poolId
        assertEq(baseStrategy.getPoolId(), _poolId);
    }

    function test_IncreasePoolAmountShouldCallOnlyAllo(uint256 _amount) external {
        baseStrategy.mock_call__checkOnlyAllo();

        // It should call onlyAllo
        baseStrategy.expectCall__checkOnlyAllo();

        baseStrategy.increasePoolAmount(_amount);
    }

    function test_IncreasePoolAmountShouldCall_beforeIncreasePoolAmount(uint256 _amount) external {
        baseStrategy.mock_call__checkOnlyAllo();

        // It should call _beforeIncreasePoolAmount
        baseStrategy.expectCall__beforeIncreasePoolAmount(_amount);

        baseStrategy.increasePoolAmount(_amount);
    }

    function test_IncreasePoolAmountShouldAddAmountToPoolAmount(uint256 _previousAmount, uint256 _amount) external {
        vm.assume(_amount < type(uint256).max - _previousAmount);
        baseStrategy.mock_call__checkOnlyAllo();
        baseStrategy.set__poolAmount(_previousAmount);

        baseStrategy.increasePoolAmount(_amount);

        // It should add amount to poolAmount
        assertEq(baseStrategy.getPoolAmount(), _previousAmount + _amount);
    }

    function test_IncreasePoolAmountShouldCall_afterIncreasePoolAmount(uint256 _amount) external {
        baseStrategy.mock_call__checkOnlyAllo();

        // It should call _afterIncreasePoolAmount
        baseStrategy.expectCall__afterIncreasePoolAmount(_amount);

        baseStrategy.increasePoolAmount(_amount);
    }

    function test_WithdrawShouldCallOnlyPoolManager() external {
        // It should call onlyPoolManager
        vm.skip(true);
    }

    function test_WithdrawShouldCall_beforeWithdraw() external {
        // It should call _beforeWithdraw
        vm.skip(true);
    }

    function test_WithdrawShouldCallBalanceOfAtToken() external {
        // It should call balanceOf at token
        vm.skip(true);
    }

    function test_WithdrawRevertWhen_AmountIsGreaterThanPoolAmount() external {
        // It should revert
        vm.skip(true);
    }

    function test_WithdrawShouldCallTransferAtToken() external {
        // It should call transfer at token
        vm.skip(true);
    }

    function test_WithdrawShouldCall_afterWithdraw() external {
        // It should call _afterWithdraw
        vm.skip(true);
    }

    function test_WithdrawShouldEmitEvent() external {
        // It should emit event
        vm.skip(true);
    }

    function test_RegisterShouldCallOnlyAllo() external {
        // It should call onlyAllo
        vm.skip(true);
    }

    function test_RegisterShouldCall_beforeRegisterRecipient() external {
        // It should call _beforeRegisterRecipient
        vm.skip(true);
    }

    function test_RegisterShouldCall_register() external {
        // It should call _register
        vm.skip(true);
    }

    function test_RegisterShouldCall_afterRegisterRecipient() external {
        // It should call _afterRegisterRecipient
        vm.skip(true);
    }

    function test_RegisterShouldReturn_recipientIds() external {
        // It should return _recipientIds
        vm.skip(true);
    }

    function test_AllocateShouldCallOnlyAllo() external {
        // It should call onlyAllo
        vm.skip(true);
    }

    function test_AllocateShouldCall_beforeAllocate() external {
        // It should call _beforeAllocate
        vm.skip(true);
    }

    function test_AllocateShouldCall_allocate() external {
        // It should call _allocate
        vm.skip(true);
    }

    function test_AllocateShouldCall_afterAllocate() external {
        // It should call _afterAllocate
        vm.skip(true);
    }

    function test_DistributeShouldCallOnlyAllo() external {
        // It should call onlyAllo
        vm.skip(true);
    }

    function test_DistributeShouldCall_beforeDistribute() external {
        // It should call _beforeDistribute
        vm.skip(true);
    }

    function test_DistributeShouldCall_distribute() external {
        // It should call _distribute
        vm.skip(true);
    }

    function test_DistributeShouldCall_afterDistribute() external {
        // It should call _afterDistribute
        vm.skip(true);
    }

    function test__checkOnlyAlloRevertWhen_CallerIsNotAllo() external {
        // It should revert
        vm.skip(true);
    }

    function test__checkOnlyPoolManagerShouldCallIsPoolManagerAtAllo() external {
        // It should call isPoolManager at allo
        vm.skip(true);
    }

    function test__checkOnlyPoolManagerRevertWhen_CallerIsNotPoolManager() external {
        // It should revert
        vm.skip(true);
    }
}

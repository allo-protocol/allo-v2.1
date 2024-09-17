// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

contract BaseStrategy is Test {
    function setUp() public {
        //
    }

    function test___BaseStrategy_initShouldCallOnlyAllo() external {
        // It should call onlyAllo
        vm.skip(true);
    }

    function test___BaseStrategy_initRevertWhen_PoolIdIsZero() external {
        // It should revert
        vm.skip(true);
    }

    function test___BaseStrategy_initRevertWhen_PoolIdArgumentIsZero() external {
        // It should revert
        vm.skip(true);
    }

    function test___BaseStrategy_initShouldSetPoolId() external {
        // It should set poolId
        vm.skip(true);
    }

    function test_IncreasePoolAmountShouldCallOnlyAllo() external {
        // It should call onlyAllo
        vm.skip(true);
    }

    function test_IncreasePoolAmountShouldCall_beforeIncreasePoolAmount() external {
        // It should call _beforeIncreasePoolAmount
        vm.skip(true);
    }

    function test_IncreasePoolAmountShouldAddAmountToPoolAmount() external {
        // It should add amount to poolAmount
        vm.skip(true);
    }

    function test_IncreasePoolAmountShouldCall_afterIncreasePoolAmount() external {
        // It should call _afterIncreasePoolAmount
        vm.skip(true);
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

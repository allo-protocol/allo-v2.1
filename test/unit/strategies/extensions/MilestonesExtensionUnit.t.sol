// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

contract MilestonesExtensionUnit is Test {
    function test___MilestonesExtension_initShouldCall_increaseMaxBid() external {
        // It should call _increaseMaxBid
        vm.skip(true);
    }

    function test_IncreaseMaxBidShouldCall_increaseMaxBid() external {
        // It should call _increaseMaxBid
        vm.skip(true);
    }

    function test_SetMilestonesWhenParametersAreValid() external {
        // It should call _validateSetMilestones
        // It should set the milestones
        // It should emit event
        vm.skip(true);
    }

    function test_SetMilestonesRevertWhen_AmountPercentageIsZero() external {
        // It should revert
        vm.skip(true);
    }

    function test_SetMilestonesRevertWhen_TotalAmountPercentageIsDifferentFrom1e18() external {
        // It should revert
        vm.skip(true);
    }

    function test_SubmitUpcomingMilestoneWhenParametersAreValid() external {
        // It should call _validateSubmitUpcomingMilestone
        // It should set the milestone metadata
        // It should set the milestone status
        // It should emit event
        vm.skip(true);
    }

    modifier whenParametersAreValid() {
        _;
    }

    function test_ReviewMilestoneWhenParametersAreValid() external whenParametersAreValid {
        // It should call _validateReviewMilestone
        // It should set the milestone status
        // It should emit event
        vm.skip(true);
    }

    function test_ReviewMilestoneWhenMilestoneStatusIsEqualToAccepted() external whenParametersAreValid {
        // It should increase upcomingMilestone
        vm.skip(true);
    }

    function test__setProposalBidRevertWhen_ProposalBidParameterIsBiggerThanMaxBid() external {
        // It should revert
        vm.skip(true);
    }

    function test__setProposalBidWhenParametersAreValid() external whenParametersAreValid {
        // It should set the _proposalBid at bids mapping
        // It should emit event
        vm.skip(true);
    }

    function test__setProposalBidWhenProposalBidIsEqualTo0() external whenParametersAreValid {
        // It should set the _proposalBid to maxBid
        vm.skip(true);
    }

    function test__validateSetMilestonesShouldCall_checkOnlyPoolManager() external {
        // It should call _checkOnlyPoolManager
        vm.skip(true);
    }

    modifier whenArrayLengthIsMoreThanZero() {
        _;
    }

    function test__validateSetMilestonesWhenArrayLengthIsMoreThanZero() external whenArrayLengthIsMoreThanZero {
        // It should delete milestones array
        vm.skip(true);
    }

    function test__validateSetMilestonesRevertWhen_FirstMilestoneStatusIsDifferentFromNone()
        external
        whenArrayLengthIsMoreThanZero
    {
        // It should revert
        vm.skip(true);
    }

    function test__validateSubmitUpcomingMilestoneRevertWhen_RecipientIsNotAccepted() external {
        // It should revert
        vm.skip(true);
    }

    function test__validateSubmitUpcomingMilestoneRevertWhen_SenderIsDifferentFromRecipientId() external {
        // It should revert
        vm.skip(true);
    }

    function test__validateSubmitUpcomingMilestoneRevertWhen_MilestoneStatusIsPending() external {
        // It should revert
        vm.skip(true);
    }

    function test__validateReviewMilestoneShouldCall_checkOnlyPoolManager() external {
        // It should call _checkOnlyPoolManager
        vm.skip(true);
    }

    function test__validateReviewMilestoneRevertWhen_ProvidedMilestoneStatusIsNone() external {
        // It should revert
        vm.skip(true);
    }

    function test__validateReviewMilestoneRevertWhen_UpcomingMilestoneStatusIsDifferentFromPending() external {
        // It should revert
        vm.skip(true);
    }

    function test__increaseMaxBidRevertWhen_ProvidedMaxBidIsBiggerThanMaxBid() external {
        // It should revert
        vm.skip(true);
    }

    function test__increaseMaxBidWhenParametersAreValid() external {
        // It should set the maxBid
        // It should emit event
        vm.skip(true);
    }

    function test__getMilestonePayoutRevertWhen_RecipientIsNotAccepted() external {
        // It should revert
        vm.skip(true);
    }

    function test__getMilestonePayoutWhenRecipientIsAccepted() external {
        // It should return the milestone payout
        vm.skip(true);
    }
}

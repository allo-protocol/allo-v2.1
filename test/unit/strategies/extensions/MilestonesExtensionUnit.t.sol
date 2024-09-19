// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockMockMilestonesExtension} from "test/smock/MockMockMilestonesExtension.sol";
import {IMilestonesExtension} from "contracts/strategies/extensions/milestones/IMilestonesExtension.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";

contract MilestonesExtensionUnit is Test {
    MockMockMilestonesExtension milestonesExtension;

    function setUp() public {
        milestonesExtension = new MockMockMilestonesExtension(address(0));
    }

    function test___MilestonesExtension_initShouldCall_increaseMaxBid(uint256 _maxBid) external {
        milestonesExtension.mock_call__increaseMaxBid(_maxBid);

        // It should call _increaseMaxBid
        milestonesExtension.expectCall__increaseMaxBid(_maxBid);

        milestonesExtension.call___MilestonesExtension_init(_maxBid);
    }

    function test_IncreaseMaxBidWhenParametersAreValid(uint256 _maxBid) external {
        milestonesExtension.mock_call__increaseMaxBid(_maxBid);
        milestonesExtension.mock_call__checkOnlyPoolManager(address(this));

        // It should call _checkOnlyPoolManager
        milestonesExtension.expectCall__checkOnlyPoolManager(address(this));

        // It should call _increaseMaxBid
        milestonesExtension.expectCall__increaseMaxBid(_maxBid);

        milestonesExtension.increaseMaxBid(_maxBid);
    }

    // IMilestonesExtension.Milestone[] memory _milestones
    function test_SetMilestonesWhenParametersAreValid() external {
        vm.skip(true);

        // milestonesExtension.mock_call__validateSetMilestones(address(this));

        // // It should call _validateSetMilestones
        // milestonesExtension.expectCall__validateSetMilestones(address(this));

        // // It should emit event
        // vm.expectEmit();
        // emit IMilestonesExtension.MilestonesSet(_milestones.length);

        // milestonesExtension.setMilestones(_milestones);

        // // It should set the milestones
        // for (uint256 i = 0; i < _milestones.length; i++) {
        //     // assertEq(milestonesExtension.getMilestone(i).amountPercentage, _milestones[i].amountPercentage);
        //     // assertEq(milestonesExtension.getMilestone(i).metadata.protocol, _milestones[i].metadata.protocol);
        //     // assertEq(milestonesExtension.getMilestone(i).metadata.pointer, _milestones[i].metadata.pointer);
        //     // assertEq(uint(milestonesExtension.getMilestone(i).status), uint(_milestones[i].status));
        // }
    }

    function test_SetMilestonesRevertWhen_AmountPercentageIsZero() external {
        // It should revert
        vm.skip(true);
    }

    function test_SetMilestonesRevertWhen_TotalAmountPercentageIsDifferentFrom1e18() external {
        // It should revert
        vm.skip(true);
    }

    function test_SubmitUpcomingMilestoneWhenParametersAreValid(address _recipientId, Metadata memory _metadata)
        external
    {
        milestonesExtension.mock_call__validateSubmitUpcomingMilestone(_recipientId, address(this));
        milestonesExtension.set__milestones(0);

        // It should call _validateSubmitUpcomingMilestone
        milestonesExtension.expectCall__validateSubmitUpcomingMilestone(_recipientId, address(this));

        // It should emit event
        vm.expectEmit();
        emit IMilestonesExtension.MilestoneSubmitted(milestonesExtension.upcomingMilestone());

        milestonesExtension.submitUpcomingMilestone(_recipientId, _metadata);

        // It should set the milestone metadata
        assertEq(
            milestonesExtension.getMilestone(milestonesExtension.upcomingMilestone()).metadata.protocol,
            _metadata.protocol
        );
        assertEq(
            milestonesExtension.getMilestone(milestonesExtension.upcomingMilestone()).metadata.pointer,
            _metadata.pointer
        );

        // It should set the milestone status
        assertEq(
            uint256(milestonesExtension.getMilestone(milestonesExtension.upcomingMilestone()).status),
            uint256(IMilestonesExtension.MilestoneStatus.Pending)
        );
    }

    modifier whenParametersAreValid(uint8 _milestoneStatus) {
        vm.assume(_milestoneStatus < 7);
        IMilestonesExtension.MilestoneStatus milestoneStatus = IMilestonesExtension.MilestoneStatus(_milestoneStatus);
        milestonesExtension.mock_call__validateReviewMilestone(address(this), milestoneStatus);
        _;
    }

    function test_ReviewMilestoneWhenParametersAreValid(uint8 _milestoneStatus)
        external
        whenParametersAreValid(_milestoneStatus)
    {
        IMilestonesExtension.MilestoneStatus milestoneStatus = IMilestonesExtension.MilestoneStatus(_milestoneStatus);
        uint256 upcomingMilestone = milestonesExtension.upcomingMilestone();
        milestonesExtension.set__milestones(upcomingMilestone);

        // It should call _validateReviewMilestone
        milestonesExtension.expectCall__validateReviewMilestone(address(this), milestoneStatus);

        // It should emit event
        vm.expectEmit();
        emit IMilestonesExtension.MilestoneStatusChanged(upcomingMilestone, milestoneStatus);

        milestonesExtension.reviewMilestone(milestoneStatus);

        // It should set the milestone status
        assertEq(uint256(milestonesExtension.getMilestone(upcomingMilestone).status), uint256(milestoneStatus));
    }

    function test_ReviewMilestoneWhenMilestoneStatusIsEqualToAccepted()
        external
        whenParametersAreValid(uint8(2)) // IMilestonesExtension.MilestoneStatus.Accepted
    {
        uint256 upcomingMilestone = milestonesExtension.upcomingMilestone();
        milestonesExtension.set__milestones(upcomingMilestone);

        milestonesExtension.reviewMilestone(IMilestonesExtension.MilestoneStatus.Accepted);

        // It should increase upcomingMilestone
        assertEq(milestonesExtension.upcomingMilestone(), upcomingMilestone + 1);
    }

    function test__setProposalBidRevertWhen_ProposalBidParameterIsBiggerThanMaxBid(
        address _bidderId,
        uint256 _proposalBid
    ) external {
        vm.assume(_proposalBid > milestonesExtension.maxBid()); // maxBid is 0

        // It should revert
        vm.expectRevert(IMilestonesExtension.EXCEEDING_MAX_BID.selector);

        milestonesExtension.call__setProposalBid(_bidderId, _proposalBid);
    }

    modifier whenParametersOfTheFunctionAreValid(uint256 _proposalBid) {
        milestonesExtension.set__maxBid(type(uint256).max);
        vm.assume(_proposalBid < milestonesExtension.maxBid());
        _;
    }

    function test__setProposalBidWhenParametersAreValid(address _bidderId, uint256 _proposalBid)
        external
        whenParametersOfTheFunctionAreValid(_proposalBid)
    {
        vm.assume(_proposalBid > 0);

        // It should emit event
        vm.expectEmit();
        emit IMilestonesExtension.SetBid(_bidderId, _proposalBid);

        milestonesExtension.call__setProposalBid(_bidderId, _proposalBid);

        // It should set the _proposalBid at bids mapping
        assertEq(milestonesExtension.bids(_bidderId), _proposalBid);
    }

    function test__setProposalBidWhenProposalBidIsEqualTo0(address _bidderId, uint256 _proposalBid)
        external
        whenParametersOfTheFunctionAreValid(_proposalBid)
    {
        _proposalBid = 0;

        milestonesExtension.call__setProposalBid(_bidderId, _proposalBid);

        // It should set the _proposalBid to maxBid
        assertEq(milestonesExtension.bids(_bidderId), type(uint256).max);
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

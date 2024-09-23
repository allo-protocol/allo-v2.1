// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

contract RecipientsExtension is Test {
    function test___RecipientsExtension_initWhenParametersAreValid() external {
        // It should set metadataRequired
        // It should call _updatePoolTimestamps
        // It should set recipientsCounter to 1
        vm.skip(true);
    }

    function test_GetRecipientWhenParametersAreValid() external {
        // It should call _getRecipient
        // It should return the recipient
        vm.skip(true);
    }

    function test__getRecipientStatusWhenParametersAreValid() external {
        // It should call _getUintRecipientStatus
        // It should return the recipient status
        vm.skip(true);
    }

    function test__isProfileMemberWhenParametersAreValid() external {
        // It should call getRegistry on allo
        // It should call getProfileByAnchor on registry
        // It should call isOwnerOrMemberOfProfile on registry
        // It should return the result
        vm.skip(true);
    }

    function test_ReviewRecipientsWhenParametersAreValid() external {
        // It should call _validateReviewRecipients
        // It should call _processStatusRow on each status
        // It should update the statusesBitMap
        // It should emit the event
        vm.skip(true);
    }

    function test_ReviewRecipientsRevertWhen_RefRecipientsCounterIsDifferentFromRecipientsCounter() external {
        // It should revert
        vm.skip(true);
    }

    function test_UpdatePoolTimestampsWhenParametersAreValid() external {
        // It should call _checkOnlyPoolManager
        // It should call _updatePoolTimestamps
        vm.skip(true);
    }

    function test__updatePoolTimestampsWhenParametersAreValid() external {
        // It should call _isPoolTimestampValid
        // It should set registrationStartTime
        // It should set registrationEndTime
        // It should emit event
        vm.skip(true);
    }

    function test__checkOnlyActiveRegistrationWhenParametersAreCorrect() external {
        // It should execute successfully
        vm.skip(true);
    }

    function test__checkOnlyActiveRegistrationRevertWhen_RegistrationStartTimeIsMoreThanBlockTimestamp() external {
        // It should revert
        vm.skip(true);
    }

    function test__checkOnlyActiveRegistrationRevertWhen_RegistrationEndTimeIsLessThanBlockTimestamp() external {
        // It should revert
        vm.skip(true);
    }

    function test__isPoolTimestampValidWhenParametersAreRight() external {
        // It should execute successfully
        vm.skip(true);
    }

    function test__isPoolTimestampValidRevertWhen_RegistrationStartTimeIsMoreThanRegistrationEndTime() external {
        // It should revert
        vm.skip(true);
    }

    function test__isPoolActiveWhenCurrentTimestampIsBetweenRegistrationStartTimeAndRegistrationEndTime() external {
        // It should return true
        vm.skip(true);
    }

    function test__isPoolActiveWhenCurrentTimestampIsLessThanRegistrationStartTimeOrMoreThanRegistrationEndTime()
        external
    {
        // It should return false
        vm.skip(true);
    }

    function test__registerWhenParametersAreValid() external {
        // It should call _checkOnlyActiveRegistration
        vm.skip(true);
    }

    modifier whenIteratingEachRecipient() {
        _;
    }

    function test__registerWhenIteratingEachRecipient() external whenIteratingEachRecipient {
        // It should call _extractRecipientAndMetadata
        // It should call _processRecipient
        // It should set recipient struct
        // It should save recipientId in the array
        vm.skip(true);
    }

    function test__registerRevertWhen_RecipientAddressIsAddressZero() external whenIteratingEachRecipient {
        // It should revert
        vm.skip(true);
    }

    function test__registerRevertWhen_MetadataRequiredIsTrueAndTheMetadataIsInvalid()
        external
        whenIteratingEachRecipient
    {
        // It should revert
        vm.skip(true);
    }

    function test__registerWhenStatusIndexIsZero() external whenIteratingEachRecipient {
        // It should set statusIndex
        // It should set recipientIndexToRecipientId mapping
        // It should call _setRecipientStatus
        // It should emit event
        // It should increment recipientsCounter
        vm.skip(true);
    }

    modifier whenStatusIndexIsDifferentThanZero() {
        _;
    }

    function test__registerWhenStatusIndexIsDifferentThanZero()
        external
        whenIteratingEachRecipient
        whenStatusIndexIsDifferentThanZero
    {
        // It should call _getUintRecipientStatus
        // It should emit event
        // It should call _getUintRecipientStatus
        vm.skip(true);
    }

    function test__registerWhenCurrentStatusIsAcceptedOrInReview()
        external
        whenIteratingEachRecipient
        whenStatusIndexIsDifferentThanZero
    {
        // It should call _setRecipientStatus with correct parameters
        vm.skip(true);
    }

    function test__registerWhenCurrentStatusIsRejected()
        external
        whenIteratingEachRecipient
        whenStatusIndexIsDifferentThanZero
    {
        // It should call _setRecipientStatus with correct parameters
        vm.skip(true);
    }

    function test__extractRecipientAndMetadataWhenParametersAreValid() external {
        // It should return metadata
        // It should return extraData
        vm.skip(true);
    }

    modifier whenDecoded_recipientIdOrRegistryAnchorIsEqualZero() {
        _;
    }

    function test__extractRecipientAndMetadataWhenDecoded_recipientIdOrRegistryAnchorIsEqualZero()
        external
        whenDecoded_recipientIdOrRegistryAnchorIsEqualZero
    {
        // It should call _isProfileMember
        // It should set isUsingRegistryAnchor as true
        // It should set recipientId as _recipientIdOrRegistryAnchor
        vm.skip(true);
    }

    function test__extractRecipientAndMetadataRevertWhen_IsNotAProfileMember()
        external
        whenDecoded_recipientIdOrRegistryAnchorIsEqualZero
    {
        // It should revert
        vm.skip(true);
    }

    function test__extractRecipientAndMetadataWhenDecoded_recipientIdOrRegistryAnchorIsDifferentFromZero() external {
        // It should set recipientId as sender
        vm.skip(true);
    }

    function test__getRecipientShouldReturnTheRecipient() external {
        // It should return the recipient
        vm.skip(true);
    }

    function test__setRecipientStatusWhenParametersAreValid() external {
        // It should call _getStatusRowColumn
        // It should set statusesBitMap
        vm.skip(true);
    }

    function test__getUintRecipientStatusWhenParametersAreValid() external {
        // It should call _getStatusRowColumn
        // It should return the status
        vm.skip(true);
    }

    function test__getUintRecipientStatusWhenStatusIndexIsZero() external {
        // It should return zero
        vm.skip(true);
    }

    function test__getStatusRowColumnShouldReturnRowIndexColIndexAndTheValueFromTheBitmap() external {
        // It should return rowIndex, colIndex and the value from the bitmap
        vm.skip(true);
    }

    modifier whenTheNewStatusIsDifferentThanTheCurrentStatus() {
        _;
    }

    function test__processStatusRowWhenTheNewStatusIsDifferentThanTheCurrentStatus()
        external
        whenTheNewStatusIsDifferentThanTheCurrentStatus
    {
        // It should call _reviewRecipientStatus
        vm.skip(true);
    }

    function test__processStatusRowWhenTheReviewedStatusIsDifferentThanNewStatus()
        external
        whenTheNewStatusIsDifferentThanTheCurrentStatus
    {
        // It should update _fullRow
        vm.skip(true);
    }

    function test__validateReviewRecipientsWhenParametersAreValid() external {
        // It should call _checkOnlyActiveRegistration
        // It should call _checkOnlyPoolManager
        vm.skip(true);
    }

    function test__reviewRecipientStatusShouldReturnTheNewStatusAs_reviewedStatus() external {
        // It should return the newStatus as _reviewedStatus
        vm.skip(true);
    }
}
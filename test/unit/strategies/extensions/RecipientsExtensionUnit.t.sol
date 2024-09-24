// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {IRecipientsExtension} from "contracts/strategies/extensions/register/IRecipientsExtension.sol";
import {IRegistry} from "contracts/core/interfaces/IRegistry.sol";
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {MockMockRecipientsExtension} from "test/smock/MockMockRecipientsExtension.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";

contract RecipientsExtensionUnit is Test {
    MockMockRecipientsExtension recipientsExtension;

    function setUp() public {
        recipientsExtension = new MockMockRecipientsExtension(address(0), true);
    }

    function test___RecipientsExtension_initWhenParametersAreValid(
        IRecipientsExtension.RecipientInitializeData memory _initData
    ) external {
        recipientsExtension.mock_call__updatePoolTimestamps(
            _initData.registrationStartTime, _initData.registrationEndTime
        );

        // It should call _updatePoolTimestamps
        recipientsExtension.expectCall__updatePoolTimestamps(
            _initData.registrationStartTime, _initData.registrationEndTime
        );

        recipientsExtension.call___RecipientsExtension_init(_initData);

        // It should set metadataRequired
        assertEq(recipientsExtension.metadataRequired(), _initData.metadataRequired);

        // It should set recipientsCounter to 1
        assertEq(recipientsExtension.recipientsCounter(), 1);
    }

    function test_GetRecipientWhenParametersAreValid(
        address _recipientId,
        IRecipientsExtension.Recipient memory _recipient
    ) external {
        recipientsExtension.mock_call__getRecipient(_recipientId, _recipient);

        // It should call _getRecipient
        recipientsExtension.expectCall__getRecipient(_recipientId);

        // It should return the recipient
        IRecipientsExtension.Recipient memory recipient = recipientsExtension.call__getRecipient(_recipientId);
        assertEq(recipient.useRegistryAnchor, _recipient.useRegistryAnchor);
        assertEq(recipient.recipientAddress, _recipient.recipientAddress);
        assertEq(recipient.statusIndex, _recipient.statusIndex);
        assertEq(recipient.metadata.protocol, _recipient.metadata.protocol);
        assertEq(recipient.metadata.pointer, _recipient.metadata.pointer);
    }

    function test__getRecipientStatusWhenParametersAreValid(address _recipientId, uint8 _statusRawEnum) external {
        vm.assume(_statusRawEnum <= 6);
        recipientsExtension.mock_call__getUintRecipientStatus(_recipientId, _statusRawEnum);

        // It should call _getUintRecipientStatus
        recipientsExtension.expectCall__getUintRecipientStatus(_recipientId);

        // It should return the recipient status
        IRecipientsExtension.Status status = recipientsExtension.call__getRecipientStatus(_recipientId);
        assertEq(uint8(status), _statusRawEnum);
    }

    function test__isProfileMemberWhenParametersAreValid(
        address _anchor,
        address _sender,
        bool _result,
        address _registry,
        IRegistry.Profile memory _profile
    ) external {
        vm.assume(_registry != address(0));
        vm.assume(_registry != address(vm));

        vm.mockCall(address(0), abi.encodeWithSelector(IAllo.getRegistry.selector), abi.encode(_registry));
        vm.mockCall(
            _registry, abi.encodeWithSelector(IRegistry.getProfileByAnchor.selector, _anchor), abi.encode(_profile)
        );
        vm.mockCall(
            _registry,
            abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector, _profile.id, _sender),
            abi.encode(_result)
        );

        // It should call getRegistry on allo
        vm.expectCall(address(0), abi.encodeWithSelector(IAllo.getRegistry.selector));

        // It should call getProfileByAnchor on registry
        vm.expectCall(_registry, abi.encodeWithSelector(IRegistry.getProfileByAnchor.selector, _anchor));

        // It should call isOwnerOrMemberOfProfile on registry
        vm.expectCall(
            _registry, abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector, _profile.id, _sender)
        );

        // It should return the result
        bool isProfileMember = recipientsExtension.call__isProfileMember(_anchor, _sender);
        assertEq(isProfileMember, _result);
    }

    function test_ReviewRecipientsWhenParametersAreValid() external {
        // It should call _validateReviewRecipients
        // It should call _processStatusRow on each status
        // It should update the statusesBitMap
        // It should emit the event
    }

    function test_ReviewRecipientsRevertWhen_RefRecipientsCounterIsDifferentFromRecipientsCounter() external {
        // It should revert
        vm.skip(true);
    }

    function test_UpdatePoolTimestampsWhenParametersAreValid(uint64 _registrationStartTime, uint64 _registrationEndTime)
        external
    {
        recipientsExtension.mock_call__checkOnlyPoolManager(address(this));
        recipientsExtension.mock_call__updatePoolTimestamps(_registrationStartTime, _registrationEndTime);

        // It should call _checkOnlyPoolManager
        recipientsExtension.expectCall__checkOnlyPoolManager(address(this));

        // It should call _updatePoolTimestamps
        recipientsExtension.expectCall__updatePoolTimestamps(_registrationStartTime, _registrationEndTime);

        recipientsExtension.updatePoolTimestamps(_registrationStartTime, _registrationEndTime);
    }

    function test__updatePoolTimestampsWhenParametersAreValid(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime
    ) external {
        recipientsExtension.mock_call__isPoolTimestampValid(_registrationStartTime, _registrationEndTime);

        // It should call _isPoolTimestampValid
        recipientsExtension.expectCall__isPoolTimestampValid(_registrationStartTime, _registrationEndTime);

        // It should emit event
        vm.expectEmit();
        emit IRecipientsExtension.RegistrationTimestampsUpdated(
            _registrationStartTime, _registrationEndTime, address(this)
        );

        recipientsExtension.call__updatePoolTimestamps(_registrationStartTime, _registrationEndTime);

        // It should set registrationStartTime
        assertEq(recipientsExtension.registrationStartTime(), _registrationStartTime);

        // It should set registrationEndTime
        assertEq(recipientsExtension.registrationEndTime(), _registrationEndTime);
    }

    function test__checkOnlyActiveRegistrationWhenParametersAreCorrect(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _blockTimestamp
    ) external {
        vm.assume(_registrationStartTime < _registrationEndTime);
        vm.assume(_registrationStartTime < _blockTimestamp);
        vm.assume(_registrationEndTime > _blockTimestamp);
        recipientsExtension.set_registrationStartTime(_registrationStartTime);
        recipientsExtension.set_registrationEndTime(_registrationEndTime);
        vm.warp(_blockTimestamp);

        // It should execute successfully
        recipientsExtension.call__checkOnlyActiveRegistration();
    }

    function test__checkOnlyActiveRegistrationRevertWhen_RegistrationStartTimeIsMoreThanBlockTimestamp(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _blockTimestamp
    ) external {
        vm.assume(_registrationStartTime < _registrationEndTime);
        vm.assume(_registrationStartTime > _blockTimestamp);
        recipientsExtension.set_registrationStartTime(_registrationStartTime);
        recipientsExtension.set_registrationEndTime(_registrationEndTime);
        vm.warp(_blockTimestamp);

        // It should revert
        vm.expectRevert(Errors.REGISTRATION_NOT_ACTIVE.selector);

        recipientsExtension.call__checkOnlyActiveRegistration();
    }

    function test__checkOnlyActiveRegistrationRevertWhen_RegistrationEndTimeIsLessThanBlockTimestamp(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _blockTimestamp
    ) external {
        vm.assume(_registrationStartTime < _registrationEndTime);
        vm.assume(_registrationEndTime < _blockTimestamp);
        recipientsExtension.set_registrationStartTime(_registrationStartTime);
        recipientsExtension.set_registrationEndTime(_registrationEndTime);
        vm.warp(_blockTimestamp);

        // It should revert
        vm.expectRevert(Errors.REGISTRATION_NOT_ACTIVE.selector);

        recipientsExtension.call__checkOnlyActiveRegistration();
    }

    function test__isPoolTimestampValidWhenParametersAreRight(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime
    ) external {
        vm.assume(_registrationStartTime < _registrationEndTime);

        // It should execute successfully
        recipientsExtension.call__isPoolTimestampValid(_registrationStartTime, _registrationEndTime);
    }

    function test__isPoolTimestampValidRevertWhen_RegistrationStartTimeIsMoreThanRegistrationEndTime(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime
    ) external {
        vm.assume(_registrationStartTime > _registrationEndTime);

        // It should revert
        vm.expectRevert(Errors.INVALID.selector);

        recipientsExtension.call__isPoolTimestampValid(_registrationStartTime, _registrationEndTime);
    }

    function test__isPoolActiveWhenCurrentTimestampIsBetweenRegistrationStartTimeAndRegistrationEndTime(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _blockTimestamp
    ) external {
        vm.assume(_registrationStartTime < _registrationEndTime);
        vm.assume(_registrationStartTime < _blockTimestamp);
        vm.assume(_registrationEndTime > _blockTimestamp);
        recipientsExtension.set_registrationStartTime(_registrationStartTime);
        recipientsExtension.set_registrationEndTime(_registrationEndTime);
        vm.warp(_blockTimestamp);

        // It should return true
        assertTrue(recipientsExtension.call__isPoolActive());
    }

    function test__isPoolActiveWhenCurrentTimestampIsLessThanRegistrationStartTimeOrMoreThanRegistrationEndTime(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _blockTimestamp
    ) external {
        vm.assume(_registrationStartTime < _registrationEndTime);
        vm.assume(_blockTimestamp < _registrationStartTime || _blockTimestamp > _registrationEndTime);
        recipientsExtension.set_registrationStartTime(_registrationStartTime);
        recipientsExtension.set_registrationEndTime(_registrationEndTime);
        vm.warp(_blockTimestamp);

        // It should return false
        assertFalse(recipientsExtension.call__isPoolActive());
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

    function test__getRecipientShouldReturnTheRecipient(
        address _recipientId,
        IRecipientsExtension.Recipient memory _recipient
    ) external {
        recipientsExtension.set__recipients(_recipientId, _recipient);

        // It should return the recipient
        IRecipientsExtension.Recipient memory recipient = recipientsExtension.call__getRecipient(_recipientId);
        assertEq(recipient.useRegistryAnchor, _recipient.useRegistryAnchor);
        assertEq(recipient.recipientAddress, _recipient.recipientAddress);
        assertEq(recipient.statusIndex, _recipient.statusIndex);
        assertEq(recipient.metadata.protocol, _recipient.metadata.protocol);
        assertEq(recipient.metadata.pointer, _recipient.metadata.pointer);
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

    function test__validateReviewRecipientsWhenParametersAreValid(address _sender) external {
        recipientsExtension.mock_call__checkOnlyPoolManager(_sender);
        recipientsExtension.mock_call__checkOnlyActiveRegistration();

        // It should call _checkOnlyActiveRegistration
        recipientsExtension.expectCall__checkOnlyActiveRegistration();

        // It should call _checkOnlyPoolManager
        recipientsExtension.expectCall__checkOnlyPoolManager(_sender);

        recipientsExtension.call__validateReviewRecipients(_sender);
    }

    function test__reviewRecipientStatusShouldReturnTheNewStatusAs_reviewedStatus(
        uint8 _newStatus,
        uint8 _oldStatus,
        uint256 _recipientIndex
    ) external {
        vm.assume(_newStatus <= 6);
        vm.assume(_oldStatus <= 6);

        // It should return the newStatus as _reviewedStatus
        IRecipientsExtension.Status status = recipientsExtension.call__reviewRecipientStatus(
            IRecipientsExtension.Status(_newStatus), IRecipientsExtension.Status(_oldStatus), _recipientIndex
        );
        assertEq(uint8(status), _newStatus);
    }
}

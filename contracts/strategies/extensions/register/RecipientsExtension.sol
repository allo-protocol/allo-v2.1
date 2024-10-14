// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Internal Imports
// Interfaces
import {IRecipientsExtension} from "strategies/extensions/register/IRecipientsExtension.sol";
import {IRegistry} from "contracts/core/interfaces/IRegistry.sol";
// Core Contracts
import {BaseStrategy} from "strategies/BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "contracts/core/libraries/Metadata.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";

abstract contract RecipientsExtension is BaseStrategy, IRecipientsExtension, Errors {
    /// @notice if set to true, `_reviewRecipientStatus()` is called for each new status update.
    bool public immutable REVIEW_EACH_STATUS;

    /// @notice Flag to indicate whether metadata is required or not.
    bool public metadataRequired;

    /// @notice The timestamp in seconds for the start time.
    uint64 public registrationStartTime;
    /// @notice The timestamp in seconds for the end time.
    uint64 public registrationEndTime;

    /// @notice The total number of recipients.
    uint256 public recipientsCounter;

    /// @notice This is a packed array of booleans, 'statuses[0]' is the first row of the bitmap and allows to
    /// store 256 bits to describe the status of 256 projects. 'statuses[1]' is the second row, and so on
    /// Instead of using 1 bit for each recipient status, we will use 4 bits for each status
    /// to allow 7 statuses:
    /// 0: none
    /// 1: pending
    /// 2: accepted
    /// 3: rejected
    /// 4: appealed
    /// 5: in review
    /// 6: canceled
    /// Since it's a mapping the storage it's pre-allocated with zero values, so if we check the
    /// status of an existing recipient, the value is by default 0 (none).
    /// If we want to check the status of a recipient, we take its index from the `recipients` array
    /// and convert it to the 2-bits position in the bitmap.
    mapping(uint256 => uint256) public statusesBitMap;

    /// @notice 'statusIndex' of recipient in bitmap => 'recipientId'.
    mapping(uint256 => address) public recipientIndexToRecipientId;

    /// @notice 'recipientId' => 'Recipient' struct.
    mapping(address => Recipient) internal _recipients;

    /// ====================================
    /// ========== Constructor =============
    /// ====================================

    /// @notice Constructor to set the RecipientsExtension
    /// @param _reviewEachStatus true if custom review logic was added.
    constructor(bool _reviewEachStatus) {
        REVIEW_EACH_STATUS = _reviewEachStatus;
    }

    /// @notice Modifier to check if the registration is active
    /// @dev This will revert if the registration has not started or if the registration has ended.
    modifier onlyActiveRegistration() {
        _checkOnlyActiveRegistration();
        _;
    }

    /// @notice Initializes this strategy as well as the BaseStrategy.
    /// @dev This function MUST be called by the 'initialize' function in the strategy.
    /// @param _initializeData The data to be decoded to initialize the strategy
    function __RecipientsExtension_init(RecipientInitializeData memory _initializeData) internal virtual {
        // Initialize required values
        metadataRequired = _initializeData.metadataRequired;

        _updatePoolTimestamps(_initializeData.registrationStartTime, _initializeData.registrationEndTime);

        recipientsCounter = 1;
    }

    /// @notice Get a recipient with a '_recipientId'
    /// @param _recipientId ID of the recipient
    /// @return _recipient The recipient details
    function getRecipient(address _recipientId) external view returns (Recipient memory _recipient) {
        return _getRecipient(_recipientId);
    }

    /// @notice Get recipient status
    /// @dev This will return the 'Status' of the recipient, the 'Status' is used at the strategy
    ///      level and is different from the 'Status' which is used at the protocol level
    /// @param _recipientId ID of the recipient
    /// @return Status of the recipient
    function _getRecipientStatus(address _recipientId) internal view virtual returns (Status) {
        return Status(_getUintRecipientStatus(_recipientId));
    }

    /// @notice Check if sender is profile owner or member
    /// @param _anchor Anchor of the profile
    /// @param _sender The sender of the transaction
    /// @return true if _sender is a profile owner or member
    function _isProfileMember(address _anchor, address _sender) internal view virtual returns (bool) {
        IRegistry _registry = _ALLO.getRegistry();
        IRegistry.Profile memory _profile = _registry.getProfileByAnchor(_anchor);
        return _registry.isOwnerOrMemberOfProfile(_profile.id, _sender);
    }

    /// @notice Sets recipient statuses.
    /// @dev The statuses are stored in a bitmap of 4 bits for each recipient. The first 4 bits of the 256 bits represent
    ///      the status of the first recipient, the second 4 bits represent the status of the second recipient, and so on.
    ///      'msg.sender' must be a pool manager.
    /// Statuses:
    /// - 0: none
    /// - 1: pending
    /// - 2: accepted
    /// - 3: rejected
    /// - 4: appealed
    /// - 5: in review
    /// - 6: canceled
    /// Emits the RecipientStatusUpdated() event.
    /// @param _statuses new statuses
    /// @param _refRecipientsCounter the recipientCounter the transaction is based on
    function reviewRecipients(ApplicationStatus[] calldata _statuses, uint256 _refRecipientsCounter) public virtual {
        _validateReviewRecipients(msg.sender);
        if (_refRecipientsCounter != recipientsCounter) revert INVALID();
        // Loop through the statuses and set the status
        for (uint256 i; i < _statuses.length; ++i) {
            uint256 _rowIndex = _statuses[i].index;
            uint256 _fullRow = _statuses[i].statusRow;

            if (REVIEW_EACH_STATUS) {
                _fullRow = _processStatusRow(_rowIndex, _fullRow);
            }

            statusesBitMap[_rowIndex] = _fullRow;

            // Emit that the recipient status has been updated with the values
            emit RecipientStatusUpdated(_rowIndex, _fullRow, msg.sender);
        }
    }

    /// @notice Sets the start and end dates.
    /// @dev The 'msg.sender' must be a pool manager.
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    function updatePoolTimestamps(uint64 _registrationStartTime, uint64 _registrationEndTime)
        external
        onlyPoolManager(msg.sender)
    {
        _updatePoolTimestamps(_registrationStartTime, _registrationEndTime);
    }

    /// @notice Sets the start and end dates.
    /// @dev The timestamps are in seconds for the start and end times. Emits a 'RegistrationTimestampsUpdated()' event.
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    function _updatePoolTimestamps(uint64 _registrationStartTime, uint64 _registrationEndTime) internal virtual {
        // If the timestamps are invalid this will revert - See details in '_isPoolTimestampValid'
        _isPoolTimestampValid(_registrationStartTime, _registrationEndTime);

        // Set the updated timestamps
        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;

        // Emit that the timestamps have been updated with the updated values
        emit RegistrationTimestampsUpdated(registrationStartTime, registrationEndTime, msg.sender);
    }

    /// @notice Checks if the registration is active and reverts if not.
    /// @dev This will revert if the registration has not started or if the registration has ended.
    function _checkOnlyActiveRegistration() internal view virtual {
        if (registrationStartTime > block.timestamp || block.timestamp > registrationEndTime) {
            revert RecipientsExtension_RegistrationNotActive();
        }
    }

    /// @notice Checks if the timestamps are valid.
    /// @dev This will revert if any of the timestamps are invalid. This is determined by the strategy
    /// and may vary from strategy to strategy. Checks if '_registrationStartTime' is greater than the '_registrationEndTime'
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    function _isPoolTimestampValid(uint64 _registrationStartTime, uint64 _registrationEndTime) internal view virtual {
        if (_registrationStartTime > _registrationEndTime) {
            revert INVALID();
        }
    }

    /// @notice Checks whether a pool is active or not.
    /// @dev This will return true if the current 'block timestamp' is greater than or equal to the
    /// 'registrationStartTime' and less than or equal to the 'registrationEndTime'.
    /// @return 'true' if pool is active, otherwise 'false'
    function _isPoolActive() internal view virtual returns (bool) {
        if (registrationStartTime <= block.timestamp && block.timestamp <= registrationEndTime) {
            return true;
        }
        return false;
    }

    /// @notice Submit recipients to pool and set their status.
    /// @param __recipients An array of recipients to be registered.
    /// @param _data An array of bytes to be decoded.
    /// @dev Each item of the array can be decoded as follows: (address _recipientIdOrRegistryAnchor, Metadata metadata, bytes extraData)
    /// @param _sender The sender of the transaction
    /// @return _recipientIds The IDs of the recipients
    function _register(address[] memory __recipients, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyActiveRegistration
        returns (address[] memory _recipientIds)
    {
        // Decode the data, datas array must be same length as recipients array
        bytes[] memory _datas = abi.decode(_data, (bytes[]));

        _recipientIds = new address[](__recipients.length);

        for (uint256 i; i < __recipients.length; i++) {
            address _recipientAddress = __recipients[i];
            bytes memory _recipientData = _datas[i];

            // decode data
            (address _recipientId, bool _isUsingRegistryAnchor, Metadata memory _metadata, bytes memory _extraData) =
                _extractRecipientAndMetadata(_recipientData, _sender);

            // Call hook
            _processRecipient(_recipientId, _isUsingRegistryAnchor, _metadata, _extraData);

            // If the recipient address is the zero address this will revert
            if (_recipientAddress == address(0)) {
                revert RecipientsExtension_RecipientError(_recipientId);
            }

            // If the metadata is required and the metadata is invalid this will revert
            if (metadataRequired && (bytes(_metadata.pointer).length == 0 || _metadata.protocol == 0)) {
                revert RecipientsExtension_InvalidMetada();
            }

            // Get the recipient
            Recipient storage _recipient = _recipients[_recipientId];

            // update the recipients data
            _recipient.recipientAddress = _recipientAddress;
            _recipient.metadata = _metadata;
            _recipient.useRegistryAnchor = _isUsingRegistryAnchor;

            if (_recipient.statusIndex == 0) {
                // recipient registering new application
                _recipient.statusIndex = uint64(recipientsCounter);
                recipientIndexToRecipientId[recipientsCounter] = _recipientId;
                _setRecipientStatus(_recipientId, uint8(Status.Pending));

                bytes memory _extendedData = abi.encode(_recipientData, recipientsCounter);
                emit Registered(_recipientId, _extendedData);

                recipientsCounter++;
            } else {
                uint8 _currentStatus = _getUintRecipientStatus(_recipientId);
                if (_currentStatus == uint8(Status.Accepted) || _currentStatus == uint8(Status.InReview)) {
                    // recipient updating accepted application
                    _setRecipientStatus(_recipientId, uint8(Status.Pending));
                } else if (_currentStatus == uint8(Status.Rejected)) {
                    // recipient updating rejected application
                    _setRecipientStatus(_recipientId, uint8(Status.Appealed));
                }
                emit UpdatedRegistration(_recipientId, _recipientData, _sender, _getUintRecipientStatus(_recipientId));
            }

            _recipientIds[i] = _recipientId;
        }
    }

    /// @notice Extract recipient and metadata from the data.
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    /// @return _recipientId The ID of the recipient
    /// @return _isUsingRegistryAnchor A flag to indicate whether to use the registry anchor or not
    /// @return _metadata The metadata of the recipient
    /// @return _extraData The extra data of the recipient
    function _extractRecipientAndMetadata(bytes memory _data, address _sender)
        internal
        view
        virtual
        returns (address _recipientId, bool _isUsingRegistryAnchor, Metadata memory _metadata, bytes memory _extraData)
    {
        address _recipientIdOrRegistryAnchor;
        (_recipientIdOrRegistryAnchor, _metadata, _extraData) = abi.decode(_data, (address, Metadata, bytes));

        // If the registry anchor is not the zero address check authorization
        // Anchor can never be zero, so if zero, set '_sender' as the recipientId
        if (_recipientIdOrRegistryAnchor != address(0)) {
            if (!_isProfileMember(_recipientIdOrRegistryAnchor, _sender)) {
                revert UNAUTHORIZED();
            }

            _isUsingRegistryAnchor = true;
            _recipientId = _recipientIdOrRegistryAnchor;
        } else {
            // Using 'isUsingRegistryAnchor' default value (false)
            _recipientId = _sender;
        }
    }

    /// @notice Get the recipient details.
    /// @param _recipientId Id of the recipient
    /// @return Recipient details
    function _getRecipient(address _recipientId) internal view virtual returns (Recipient memory) {
        return _recipients[_recipientId];
    }

    /// @notice Set the recipient status.
    /// @param _recipientId ID of the recipient
    /// @param _status Status of the recipient
    function _setRecipientStatus(address _recipientId, uint256 _status) internal virtual {
        // Get the row index, column index and current row
        (uint256 _rowIndex, uint256 _colIndex, uint256 _currentRow) = _getStatusRowColumn(_recipientId);

        // Calculate the 'newRow'
        uint256 _newRow = _currentRow & ~(15 << _colIndex);

        // Add the status to the mapping
        statusesBitMap[_rowIndex] = _newRow | (_status << _colIndex);
    }

    /// @notice Get recipient status
    /// @param _recipientId ID of the recipient
    /// @return _status The status of the recipient
    function _getUintRecipientStatus(address _recipientId) internal view virtual returns (uint8 _status) {
        if (_recipients[_recipientId].statusIndex == 0) return 0;
        // Get the column index and current row
        (, uint256 _colIndex, uint256 _currentRow) = _getStatusRowColumn(_recipientId);

        // Get the status from the 'currentRow' shifting by the 'colIndex'
        _status = uint8((_currentRow >> _colIndex) & 15);
    }

    /// @notice Get recipient status 'rowIndex', 'colIndex' and 'currentRow'.
    /// @param _recipientId ID of the recipient
    /// @return _rowIndex
    /// @return _colIndex
    /// @return _currentRow
    function _getStatusRowColumn(address _recipientId) internal view virtual returns (uint256, uint256, uint256) {
        uint256 _recipientIndex = _recipients[_recipientId].statusIndex - 1;

        uint256 _rowIndex = _recipientIndex / 64; // 256 / 4
        uint256 _colIndex = (_recipientIndex % 64) * 4;

        return (_rowIndex, _colIndex, statusesBitMap[_rowIndex]);
    }

    /// @notice Called from reviewRecipients if REVIEW_EACH_STATUS is set to true.
    /// @dev Each new status in the statuses row (_fullrow) gets isolated and sent to _reviewRecipientStatus for review.
    /// @param _rowIndex Row index in the statusesBitMap mapping
    /// @param _fullRow New row of statuses
    /// @return The _fullRow with any modifications made by _reviewRecipientStatus()
    function _processStatusRow(uint256 _rowIndex, uint256 _fullRow) internal virtual returns (uint256) {
        // Loop through each status in the updated row
        uint256 _currentRow = statusesBitMap[_rowIndex];
        for (uint256 col = 0; col < 64; ++col) {
            // Extract the status at the column index
            uint256 _colIndex = col << 2; // col * 4
            Status _newStatus = Status(uint8((_fullRow >> _colIndex) & 0xF));
            Status _currentStatus = Status(uint8((_currentRow >> _colIndex) & 0xF));

            // Only do something if the status is being modified
            if (_newStatus != _currentStatus) {
                uint256 _recipientIndex = (_rowIndex << 6) + col + 1; // _rowIndex * 64 + col + 1
                Status _reviewedStatus = _reviewRecipientStatus(_newStatus, _currentStatus, _recipientIndex);
                if (_reviewedStatus != _newStatus) {
                    // Update `_fullRow` with the reviewed status.
                    uint256 reviewedRow = _fullRow & ~(0xF << _colIndex);
                    _fullRow = reviewedRow | (uint256(_reviewedStatus) << _colIndex);
                }
            }
        }
        return _fullRow;
    }

    /// @notice Hook validate whether `_sender` can call reviewRecipients at this point
    /// @param _sender The address reviewing the recipients
    function _validateReviewRecipients(address _sender) internal virtual {
        _checkOnlyActiveRegistration();
        _checkOnlyPoolManager(_sender);
    }

    /// @notice Hook to review each new recipient status when REVIEW_EACH_STATUS is set to true
    /// @dev Beware of gas costs, since this function will be called for each reviewed recipient
    /// @param _newStatus New proposed status
    /// @param _oldStatus Previous status
    /// @param _recipientIndex The index of the recipient in case the recipient data needs to be accessed
    /// @return _reviewedStatus The actual new status to use
    function _reviewRecipientStatus(Status _newStatus, Status _oldStatus, uint256 _recipientIndex)
        internal
        virtual
        returns (Status _reviewedStatus)
    {
        _reviewedStatus = _newStatus;
    }

    /// @notice Hook to process recipient data
    /// @param _recipientId ID of the recipient
    /// @param _isUsingRegistryAnchor A flag to indicate whether to use the registry anchor or not
    /// @param _metadata The metadata of the recipient
    /// @param _extraData The extra data of the recipient
    function _processRecipient(
        address _recipientId,
        bool _isUsingRegistryAnchor,
        Metadata memory _metadata,
        bytes memory _extraData
    ) internal virtual {}
}

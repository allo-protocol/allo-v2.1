// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Internal Imports
// Core Contracts
import {BaseStrategy} from "strategies/BaseStrategy.sol";
import {Transfer} from "contracts/core/libraries/Transfer.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";

/// @title NFT Gating Extension
/// @notice This contract is providing nft gating options for a strategy's calls
/// @dev This contract is inheriting BaseStrategy
abstract contract BountyExtension is BaseStrategy {
    using Transfer for address;

    enum Status {
        None,
        Pending,
        Paid
    }

    struct Bounty {
        address token;
        Status status;
        Metadata metadata;
        bytes data;
    }

    // if we don't add any fields to application,
    // we can remove this struct and save only the metadata
    struct BountyApplication {
        uint256 bountyId;
        address recipientId;
        Metadata metadata;
        bytes data;
    }
    // maybe recipientAddress?

    /// ===============================
    /// ========== Storage ============
    /// ===============================

    /// @notice Counter for the number of bounties created
    uint256 public bountyIdCounter;

    /// @notice Mapping of bounty id to bounty
    mapping(uint256 => Bounty) public bounties;

    /// @notice Mapping of bounty id to recipientAddress to bounty application
    mapping(uint256 => mapping(address => BountyApplication)) public bountyApplications;

    /// ================================
    /// ========== Events ==============
    /// ================================
    event BountyCreated(uint256 indexed bountyId, Bounty bounty);

    /// ================================
    /// ========== Errors ==============
    /// ================================

    error ProfileBounties_InvalidData();
    error ProfileBounties_NotImplemented();
    error ProfileBounties_AlreadyDistributed();

    /// ==============================
    /// ========= Modifiers ==========
    /// ==============================

    /// ===============================
    /// ======= Internal Functions ====
    /// ===============================

    function __BountyExtension_init() internal {
        // todo: no code?
    }

    function _getBountyIdFromExtraData(bytes memory _data) internal view virtual returns (uint256);

    function _processRecipient(
        address _recipientId,
        bool _isUsingRegistryAnchor,
        Metadata memory _metadata,
        bytes memory _extraData
    ) internal {
        uint256 bountyId = _getBountyIdFromExtraData(_extraData);
        _revertInvalidBounty(bountyId);

        BountyApplication memory _bountyApplication =
            BountyApplication({bountyId: bountyId, recipientId: _recipientId, metadata: _metadata});
        // add additional fields here

        bountyApplications[bountyId][_recipientId] = _bountyApplication;
        // should we emit an event here or can we rely on the Registered Event?
    }

    /// @inheritdoc BaseStrategy
    function _allocate(address[] memory, uint256[] memory, bytes memory, address) internal virtual override {
        revert ProfileBounties_NotImplemented();
    }

    function _createBounty(address _token, Metadata memory _metadata, bytes _data)
        internal
        onlyPoolManager(msg.sender)
    {
        Bounty memory _bounty = Bounty({token: _token, status: Status.Pending, metadata: _metadata, data: _data});

        bountyIdCounter++;
        bounties[bountyIdCounter] = _bounty;

        emit BountyCreated(bountyIdCounter, _bounty);
    }

    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyPoolManager(msg.sender)
    {
        uint256[] memory _bountyIds = _getBountyIdsFromDistributeData(_data);
        bytes[] memory _datas = abi.decode(_data, (bytes[]));

        uint256 _bountiesLength = _bountyIds.length;
        uint256 _datasLength = _datas.length;

        if (_recipientIds.length != _bountiesLength || _bountiesLength != _datasLength) {
            revert ProfileBounties_InvalidData();
        }

        for (uint256 i = 0; i < _bountiesLength; i++) {
            uint256 bountyId = _bountyIds[i];
            address recipientId = _recipientIds[i];

            _revertInvalidBounty(bountyId, _datas[i]);
            _checkRecipientValidity(recipientId, bountyId, _datas[i]);
            _handleDistributedBountyState(recipientId, bountyId, _datas[i]);
            _transferDistribution(recipientId, bountyId, _datas[i]);
        }

        // emit Distribute(_recipientIds, _data, _sender);
    }

    function _getBountyIdsFromDistributeData(bytes memory _data) internal view virtual returns (uint256[] memory) {
        uint256[] memory _bountyIds = abi.decode(_data, (uint256[]));
        return _bountyIds;
    }

    function _revertInvalidBounty(uint256 _bountyId, bytes memory _data) internal virtual {
        Bounty memory bounty = bounties[_bountyId];
        if (bounty.token == address(0) || bounty.status != Status.Pending) {
            revert ProfileBounties_InvalidData();
        }
    }

    function _checkRecipientValidity(address _recipientId, uint256 _bountyId, bytes memory _data) internal virtual {
        if (bountyApplications[_bountyId][_recipientId].bountyId != _bountyId) {
            revert ProfileBounties_InvalidData();
        }
    }

    function _handleDistributedBountyState(address _recipientId, uint256 _bountyId, bytes memory _data) internal virtual {
        Bounty storage _bounty = bounties[bountyId];
        _bounty.status = Status.Paid;
    }

    function _getAmountFromBountyData(bytes memory _data) internal view virtual returns (uint256) {
        return abi.decode(_data, (uint256));
    }

    function _transferDistribution(address _recipientId, uint256 _bountyId, bytes memory _data) internal virtual {
        // todo: _bounty.token.transfer(_recipientId, _getAmountFromBountyData(bounties[_bountyId].data));
    }

    /// ====================================
    /// ============ External ==============
    /// ====================================

    function createBounties(address[] memory _tokens, bytes[] memory _data, Metadata[] memory _metadata) external {
        uint256 _tokensLength = _tokens.length;
        if (_tokensLength != _data.length || _tokensLength != _metadata.length) {
            revert ProfileBounties_InvalidData();
        }

        for (uint256 i = 0; i < _tokensLength; i++) {
            _createBounty(_tokens[i], _data[i], _metadata[i]);
        }
    }
}

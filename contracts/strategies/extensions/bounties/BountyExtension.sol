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

    struct Bounty {
        address token;
        address acceptedRecipient; // instead of status
        uint256 amount;
        Metadata metadata;
    }

    // if we don't add any fields to application,
    // we can remove this struct and save only the metadata
    struct BountyApplication {
        uint256 bountyId;
        address recipientId;
        Metadata metadata;
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

    function _getBountyIdFromExtraData(bytes memory _data) internal virtual view returns (uint256);

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

    function _createBounty(address _token, uint256 _amount, Metadata memory _metadata) internal onlyPoolManager(msg.sender) {
        Bounty memory _bounty =
            Bounty({token: _token, acceptedRecipient: address(0), amount: _amount, metadata: _metadata});

        bountyIdCounter++;
        bounties[bountyIdCounter] = _bounty;

        emit BountyCreated(bountyIdCounter, _bounty);
    }

    function _revertInvalidBounty(uint256 _bountyId) internal {
        Bounty memory bounty = bounties[_bountyId];
        if (bounty.token == address(0) || bounty.acceptedRecipient != address(0)) {
            revert ProfileBounties_InvalidData();
        }
    }

    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyPoolManager(msg.sender)
    {
        uint256[] memory _bountyIds = abi.decode(_data, (uint256[]));

        uint256 _bountiesLength = _bountyIds.length;

        if (_recipientIds.length != _bountiesLength) {
            revert ProfileBounties_InvalidData();
        }

        for (uint256 i = 0; i < _bountiesLength; i++) {
            uint256 bountyId = _bountyIds[i];
            address recipientId = _recipientIds[i];
            _revertInvalidBounty(bountyId);

            if (bountyApplications[bountyId][recipientId].bountyId != bountyId) {
                revert ProfileBounties_InvalidData();
            }

            Bounty storage _bounty = bounties[bountyId];
            _bounty.acceptedRecipient = recipientId;
            // todo: _bounty.token.transfer(recipientId, _bounty.amount);
        }

        // emit Distribute(_recipientIds, _data, _sender);
    }

    /// ====================================
    /// ============ External ==============
    /// ====================================

    function createBounties(address[] memory _tokens, uint256[] memory _amounts, Metadata[] memory _metadata)
        external
    {
        uint256 _tokensLength = _tokens.length;
        if (_tokensLength != _amounts.length || _tokensLength != _metadata.length) {
            revert ProfileBounties_InvalidData();
        }

        for (uint256 i = 0; i < _tokensLength; i++) {
            _createBounty(_tokens[i], _amounts[i], _metadata[i]);
        }
    }
}

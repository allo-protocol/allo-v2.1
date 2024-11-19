// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// External Imports
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

/// @title QV Helper Library
/// @notice A helper library for Quadratic Voting
/// @dev Handles the voting of recipients and calculates the payout amount for each recipient
library QVHelper {
    /// @notice Error thrown when the number of recipients and amounts are not equal on voting
    error QVHelper_LengthMissmatch();

    /// @notice Struct that holds the state of the voting
    /// @param totalVotes The total amount of votes casted
    /// @param totalVoiceCredits The total amount of voice credits casted
    /// @param recipientVoiceCredits The voice credits casted for each recipient
    /// @param recipientVotes The votes casted for each recipient
    struct VotingState {
        uint256 totalVotes;
        uint256 totalVoiceCredits;
        mapping(address => uint256) recipientVoiceCredits;
        mapping(address => uint256) recipientVotes;
    }

    /// @notice Votes for recipients
    /// @param _state The voting state
    /// @param _recipients The recipients to vote
    /// @param _voiceCredits The amounts of voice credits to cast for each recipient
    /// @dev The number of recipients and voiceCredits should be equal and the same index should correspond to the same recipient and amount
    function voteWithVoiceCredits(
        VotingState storage _state,
        address[] memory _recipients,
        uint256[] memory _voiceCredits
    ) internal {
        /// Check if the number of recipients and amounts are equal
        if (_recipients.length != _voiceCredits.length) revert QVHelper_LengthMissmatch();

        for (uint256 i; i < _recipients.length; i++) {
            voteSingleWithVoiceCredits(_state, _recipients[i], _voiceCredits[i]);
        }
    }

    /// @notice Votes for a single recipient
    /// @param _state The voting state
    /// @param _recipient The recipient to vote
    /// @param _voiceCredits The amount of voice credits to cast
    function voteSingleWithVoiceCredits(VotingState storage _state, address _recipient, uint256 _voiceCredits)
        internal
    {
        // Add the voice credits to the recipient
        _state.recipientVoiceCredits[_recipient] += _voiceCredits;
        uint256 _votes = FixedPointMathLib.sqrt(_voiceCredits);
        // Add the votes to the recipient
        _state.recipientVotes[_recipient] += _votes;
        // Add the total voice credits
        _state.totalVoiceCredits += _voiceCredits;
        // Add the total votes
        _state.totalVotes += _votes;
    }

    /// @notice Votes for recipients
    /// @param _state The voting state
    /// @param _recipients The recipients to vote
    /// @param _votes The amounts of votes to cast for each recipient
    /// @dev The number of recipients and votes should be equal and the same index should correspond to the same recipient and amount
    function vote(VotingState storage _state, address[] memory _recipients, uint256[] memory _votes) internal {
        /// Check if the number of recipients and amounts are equal
        if (_recipients.length != _votes.length) revert QVHelper_LengthMissmatch();

        for (uint256 i; i < _recipients.length; i++) {
            voteSingle(_state, _recipients[i], _votes[i]);
        }
    }

    /// @notice Votes for a single recipient
    /// @param _state The voting state
    /// @param _recipient The recipient to vote
    /// @param _votes The amount of votes to cast
    function voteSingle(VotingState storage _state, address _recipient, uint256 _votes) internal {
        // Add the votes to the recipient
        _state.recipientVotes[_recipient] += _votes;
        // Add the total votes
        _state.totalVotes += _votes;
        // voiceCredits = votes^2
        uint256 _voiceCredits = _votes * _votes;
        // Add the voice credits to the recipient
        _state.recipientVoiceCredits[_recipient] += _voiceCredits;
        // Add total voice credits
        _state.totalVoiceCredits += _voiceCredits;
    }

    /// @notice Calculate the payout for each recipient
    /// @param _state The state of the Quadratic Voting
    /// @param _recipients The recipients
    /// @param _poolAmount The amount of the pool
    /// @return _payouts The payouts for each recipient
    function getPayout(VotingState storage _state, address[] memory _recipients, uint256 _poolAmount)
        internal
        view
        returns (uint256[] memory _payouts)
    {
        _payouts = new uint256[](_recipients.length);

        for (uint256 i; i < _recipients.length; i++) {
            /// Get the recipient
            address _recipient = _recipients[i];
            /// Get the votes of the recipient
            uint256 _recipientVotes = _state.recipientVotes[_recipient];
            /// Calculate the payout for the recipient
            _payouts[i] = _poolAmount * _recipientVotes / _state.totalVotes;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// External Imports
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

/// @title QF Helper Library
/// @notice A helper library for Quadratic Funding
/// @dev Handles the donation and voting of recipients and calculates the matching amount
///      for each recipient using the Quadratic Funding formula
library QFHelper {
    /// @notice Error thrown when the number of recipients and amounts are not equal
    error QFHelper_LengthMissmatch();

    /// @notice Struct that defines the state of the donations to recipients
    /// @param sqrtDonationsSum The sum of the square root of the donations for each recipient
    /// @param totalContributions The total contributions of all recipients
    struct State {
        mapping(address => uint256) sqrtDonationsSum;
        uint256 totalContributions;
    }

    /// @notice Votes for recipients by donating
    /// @dev The number of recipients and amounts should be equal and the same index
    ///      should correspond to the same recipient and amount
    /// @dev We also calculate the total contributions and sqrt sum of donations for each recipient
    ///      which will be needed to calculate the matching amount
    /// @param _state The state of the donations
    /// @param _recipients The recipients to donate to
    /// @param _amounts The amounts to donate to each recipient
    function fund(State storage _state, address[] memory _recipients, uint256[] memory _amounts) internal {
        uint256 _recipientsLength = _recipients.length;
        // Check if the number of recipients and amounts are equal
        if (_recipientsLength != _amounts.length) revert QFHelper_LengthMissmatch();

        for (uint256 i = 0; i < _recipientsLength; i++) {
            // Call fundSingle for each recipient and amount pair
            fundSingle(_state, _recipients[i], _amounts[i]);
        }
    }

    /// @notice Votes for a single recipient by donating
    /// @param _state The state of the donations
    /// @param _recipient The recipient to donate to
    /// @param _amount The amount to donate to the recipient
    function fundSingle(State storage _state, address _recipient, uint256 _amount) internal {
        // Calculate the square root of the donation amount and add it to the sum of donations
        uint256 _sqrtDonationsSum = _state.sqrtDonationsSum[_recipient];
        _sqrtDonationsSum += FixedPointMathLib.sqrt(_amount);

        // Calculate the contribution delta for this single recipient
        uint256 _contributionDelta = _sqrtDonationsSum ** 2 - _state.sqrtDonationsSum[_recipient] ** 2;

        // Update the state
        _state.sqrtDonationsSum[_recipient] = _sqrtDonationsSum;
        _state.totalContributions += _contributionDelta;
    }

    /// @notice Calculates the matching amount for a recipient using the Quadratic Funding formula
    /// @param _state The state of the donations
    /// @param _matchingAmount The total matching amount
    /// @param _recipient The recipient to calculate the matching amount for
    /// @return _amount The matching amount for the recipient
    function calculateMatching(State storage _state, uint256 _matchingAmount, address _recipient)
        internal
        view
        returns (uint256 _amount)
    {
        /// get the sqrt sum of donations for the recipient
        uint256 _sqrtDonationsSum = _state.sqrtDonationsSum[_recipient];
        /// square the sqrt sum of donations
        uint256 _squareDonationsSum = _sqrtDonationsSum * _sqrtDonationsSum;

        /// calculate the matching amount
        _amount = _squareDonationsSum * _matchingAmount / _state.totalContributions;
    }
}

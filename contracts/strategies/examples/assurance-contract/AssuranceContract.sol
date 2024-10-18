// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {BaseStrategy} from "../../BaseStrategy.sol";
import {IAllo} from "../../../core/interfaces/IAllo.sol";

/// @title AssuranceContract
/// @notice This contract implements an assurance contract strategy for crowdfunding.
/// @dev Extends BaseStrategy to integrate with the Allo protocol.
contract AssuranceContract is BaseStrategy {
    /// @notice Struct to store campaign details
    struct Campaign {
        uint256 goal;        // The funding goal of the campaign
        uint256 totalPledged; // Total amount pledged so far
        uint256 deadline;    // Timestamp when the campaign ends
        address beneficiary; // Address to receive funds if goal is met
        bool finalized;      // Whether the campaign has been finalized
    }

    /// @notice Mapping of pool IDs to Campaign structs
    mapping(uint256 => Campaign) public campaigns;

    /// @notice Mapping of pool IDs to contributor addresses to pledge amounts
    mapping(uint256 => mapping(address => uint256)) public pledges;

    /// @notice Event emitted when a new campaign is created
    event CampaignCreated(uint256 indexed poolId, uint256 goal, uint256 deadline, address beneficiary);

    /// @notice Event emitted when a pledge is made
    event Pledged(uint256 indexed poolId, address indexed contributor, uint256 amount);

    /// @notice Event emitted when a campaign reaches its goal
    event GoalReached(uint256 indexed poolId);

    /// @notice Event emitted when funds are claimed by the beneficiary
    event FundsClaimed(uint256 indexed poolId, address beneficiary, uint256 amount);

    /// @notice Event emitted when funds are refunded to a contributor
    event FundsRefunded(uint256 indexed poolId, address contributor, uint256 amount);

    /// @notice Constructor to initialize the AssuranceContract
    /// @param _allo The address of the Allo contract
    constructor(address _allo) BaseStrategy(_allo, "AssuranceContract") {}

    /// @notice Initializes a new campaign for a pool
    /// @dev This function is called by Allo when a new pool is created
    /// @param _poolId The ID of the pool
    /// @param _data Encoded initialization parameters (goal, deadline, beneficiary)
    function initialize(uint256 _poolId, bytes memory _data) external override {
        // Call the initialize function from the BaseStrategy
        __BaseStrategy_init(_poolId);

        // Decode the initialization data
        (uint256 goal, uint256 deadline, address beneficiary) = abi.decode(_data, (uint256, uint256, address));

        // Create and store the new campaign
        campaigns[_poolId] = Campaign(goal, 0, deadline, beneficiary, false);

        // Emit an event for the new campaign
        emit CampaignCreated(_poolId, goal, deadline, beneficiary);
    }

    /// @notice Allows a user to pledge funds to a campaign
    /// @param _poolId The ID of the pool/campaign
    function pledge(uint256 _poolId) external payable {
        Campaign storage campaign = campaigns[_poolId];

        // Ensure the campaign hasn't ended
        require(block.timestamp < campaign.deadline, "Campaign ended");
        // Ensure the campaign hasn't been finalized
        require(!campaign.finalized, "Campaign already finalized");

        // Update the pledge amount for the contributor
        pledges[_poolId][msg.sender] += msg.value;
        // Update the total pledged amount for the campaign
        campaign.totalPledged += msg.value;

        // Emit an event for the pledge
        emit Pledged(_poolId, msg.sender, msg.value);

        // Check if the goal has been reached
        if (campaign.totalPledged >= campaign.goal) {
            emit GoalReached(_poolId);
        }
    }

    /// @notice Allows the beneficiary to claim funds if the goal is met
    /// @param _poolId The ID of the pool/campaign
    function claimFunds(uint256 _poolId) external {
        Campaign storage campaign = campaigns[_poolId];

        // Ensure the campaign has ended
        require(block.timestamp >= campaign.deadline, "Campaign not ended");
        // Ensure the goal was reached
        require(campaign.totalPledged >= campaign.goal, "Goal not reached");
        // Ensure the campaign hasn't been finalized yet
        require(!campaign.finalized, "Funds already claimed");

        // Mark the campaign as finalized
        campaign.finalized = true;

        // Transfer the funds to the beneficiary
        uint256 amount = campaign.totalPledged;
        (bool success, ) = campaign.beneficiary.call{value: amount}("");
        require(success, "Transfer failed");

        // Emit an event for the claimed funds
        emit FundsClaimed(_poolId, campaign.beneficiary, amount);
    }

    /// @notice Allows contributors to get a refund if the goal wasn
    function refund(uint256 _poolId) external {
        Campaign storage campaign = campaigns[_poolId];

        // Ensure the campaign has ended
        require(block.timestamp >= campaign.deadline, "Campaign not ended");
        // Ensure the goal was not reached
        require(campaign.totalPledged < campaign.goal, "Goal was reached");
        // Ensure the campaign hasn't been finalized
        require(!campaign.finalized, "Campaign already finalized");

        // Get the refund amount for the contributor
        uint256 amount = pledges[_poolId][msg.sender];
        require(amount > 0, "No funds to refund");

        // Reset the pledge amount for the contributor
        pledges[_poolId][msg.sender] = 0;

        // Transfer the refund to the contributor
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // Emit an event for the refund
        emit FundsRefunded(_poolId, msg.sender, amount);
    }

    // ... (other required functions)

    /// @notice Implementation of the allocate function required by BaseStrategy
    /// @dev This function is not used in this strategy and will revert if called
    function _allocate(
        address[] memory,
        uint256[] memory,
        bytes memory,
        address
    ) internal virtual override {
        revert("AssuranceContract: Allocate not implemented");
    }

    /// @notice Implementation of the distribute function required by BaseStrategy
    /// @dev This function is not used in this strategy and will revert if called
    function _distribute(
        address[] memory,
        bytes memory,
        address
    ) internal virtual override {
        revert("AssuranceContract: Distribute not implemented");
    }

    /// @notice Implementation of the register function required by BaseStrategy
    /// @dev This function is not used in this strategy and will revert if called
    function _register(
        address[] memory,
        bytes memory,
        address
    ) internal virtual override returns (address[] memory) {
        revert("AssuranceContract: Register not implemented");
    }
}

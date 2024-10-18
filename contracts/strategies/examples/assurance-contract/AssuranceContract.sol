// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseStrategy} from "strategies/BaseStrategy.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {Transfer} from "contracts/core/libraries/Transfer.sol";

contract AssuranceContract is BaseStrategy, Errors {
    using Transfer for address;

    struct Campaign {
        uint256 goal;
        uint256 totalPledged;
        uint256 deadline;
        address beneficiary;
        bool finalized;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public pledges;

    event CampaignCreated(uint256 indexed campaignId, uint256 goal, uint256 deadline, address beneficiary);
    event Pledged(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event GoalReached(uint256 indexed campaignId);
    event FundsClaimed(uint256 indexed campaignId, address beneficiary, uint256 amount);
    event FundsRefunded(uint256 indexed campaignId, address contributor, uint256 amount);

    constructor(address _allo) BaseStrategy(_allo, "AssuranceContract") {}

    function initialize(uint256 _poolId, bytes memory _data) external override {
        __BaseStrategy_init(_poolId);
        (uint256 goal, uint256 deadline, address beneficiary) = abi.decode(_data, (uint256, uint256, address));
        campaigns[_poolId] = Campaign(goal, 0, deadline, beneficiary, false);
        emit CampaignCreated(_poolId, goal, deadline, beneficiary);
    }

    function pledge(uint256 _campaignId) external payable {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp < campaign.deadline, "Campaign ended");
        require(!campaign.finalized, "Campaign already finalized");

        pledges[_campaignId][msg.sender] += msg.value;
        campaign.totalPledged += msg.value;

        emit Pledged(_campaignId, msg.sender, msg.value);

        if (campaign.totalPledged >= campaign.goal) {
            emit GoalReached(_campaignId);
        }
    }

    function claimFunds(uint256 _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp >= campaign.deadline, "Campaign not ended");
        require(campaign.totalPledged >= campaign.goal, "Goal not reached");
        require(!campaign.finalized, "Funds already claimed");

        campaign.finalized = true;
        uint256 amount = campaign.totalPledged;
        Transfer.NATIVE.transferAmount(campaign.beneficiary, amount);

        emit FundsClaimed(_campaignId, campaign.beneficiary, amount);
    }

    function refund(uint256 _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp >= campaign.deadline, "Campaign not ended");
        require(campaign.totalPledged < campaign.goal, "Goal was reached");
        require(!campaign.finalized, "Campaign already finalized");

        uint256 amount = pledges[_campaignId][msg.sender];
        require(amount > 0, "No funds to refund");

        pledges[_campaignId][msg.sender] = 0;
        Transfer.NATIVE.transferAmount(msg.sender, amount);

        emit FundsRefunded(_campaignId, msg.sender, amount);
    }

    // ... (other required functions)

    function _allocate(address[] memory, uint256[] memory, bytes memory, address) internal override {
        revert NOT_IMPLEMENTED();
    }

    function _distribute(address[] memory, bytes memory, address) internal override {
        revert NOT_IMPLEMENTED();
    }

    function _register(address[] memory, bytes memory, address) internal override returns (address[] memory) {
        revert NOT_IMPLEMENTED();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {BaseStrategy} from "../../BaseStrategy.sol";
import {IAllo} from "../../../core/interfaces/IAllo.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title AssuranceContract
/// @notice This contract implements an assurance contract strategy for crowdfunding, supporting both ETH and ERC20 tokens.
/// @dev Extends BaseStrategy to integrate with the Allo protocol.
contract AssuranceContract is BaseStrategy {
    using SafeERC20 for IERC20;

    struct Campaign {
        uint256 goal;
        uint256 totalPledged;
        uint256 deadline;
        address beneficiary;
        bool finalized;
        address tokenAddress; // Address of ERC20 token, or address(0) for ETH
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public pledges;

    event CampaignCreated(uint256 indexed poolId, uint256 goal, uint256 deadline, address beneficiary, address tokenAddress);
    event Pledged(uint256 indexed poolId, address indexed contributor, uint256 amount);
    event GoalReached(uint256 indexed poolId);
    event FundsClaimed(uint256 indexed poolId, address beneficiary, uint256 amount);
    event FundsRefunded(uint256 indexed poolId, address contributor, uint256 amount);

    constructor(address _allo) BaseStrategy(_allo, "AssuranceContract") {}

    function initialize(uint256 _poolId, bytes memory _data) external override {
        __BaseStrategy_init(_poolId);

        (uint256 goal, uint256 deadline, address beneficiary, address tokenAddress) = abi.decode(_data, (uint256, uint256, address, address));

        campaigns[_poolId] = Campaign(goal, 0, deadline, beneficiary, false, tokenAddress);

        emit CampaignCreated(_poolId, goal, deadline, beneficiary, tokenAddress);
    }

    function pledge(uint256 _poolId, uint256 _amount) external payable {
        Campaign storage campaign = campaigns[_poolId];

        require(block.timestamp < campaign.deadline, "Campaign ended");
        require(!campaign.finalized, "Campaign already finalized");

        if (campaign.tokenAddress == address(0)) {
            require(msg.value == _amount, "Incorrect ETH amount");
            campaign.totalPledged += msg.value;
            pledges[_poolId][msg.sender] += msg.value;
        } else {
            IERC20 token = IERC20(campaign.tokenAddress);
            uint256 balanceBefore = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 balanceAfter = token.balanceOf(address(this));
            uint256 actualAmount = balanceAfter - balanceBefore;
            campaign.totalPledged += actualAmount;
            pledges[_poolId][msg.sender] += actualAmount;
        }

        emit Pledged(_poolId, msg.sender, _amount);

        if (campaign.totalPledged >= campaign.goal) {
            emit GoalReached(_poolId);
        }
    }

    function claimFunds(uint256 _poolId) external {
        Campaign storage campaign = campaigns[_poolId];

        require(block.timestamp >= campaign.deadline, "Campaign not ended");
        require(campaign.totalPledged >= campaign.goal, "Goal not reached");
        require(!campaign.finalized, "Funds already claimed");

        campaign.finalized = true;
        uint256 amount = campaign.totalPledged;

        if (campaign.tokenAddress == address(0)) {
            (bool success, ) = campaign.beneficiary.call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20 token = IERC20(campaign.tokenAddress);
            token.safeTransfer(campaign.beneficiary, amount);
        }

        emit FundsClaimed(_poolId, campaign.beneficiary, amount);
    }

    function refund(uint256 _poolId) external {
        Campaign storage campaign = campaigns[_poolId];

        require(block.timestamp >= campaign.deadline, "Campaign not ended");
        require(campaign.totalPledged < campaign.goal, "Goal was reached");
        require(!campaign.finalized, "Campaign already finalized");

        uint256 amount = pledges[_poolId][msg.sender];
        require(amount > 0, "No funds to refund");

        pledges[_poolId][msg.sender] = 0;

        if (campaign.tokenAddress == address(0)) {
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20 token = IERC20(campaign.tokenAddress);
            token.safeTransfer(msg.sender, amount);
        }

        emit FundsRefunded(_poolId, msg.sender, amount);
    }

    function _allocate(address[] memory, uint256[] memory, bytes memory, address) internal virtual override {
        revert("AssuranceContract: Allocate not implemented");
    }

    function _distribute(address[] memory, bytes memory, address) internal virtual override {
        revert("AssuranceContract: Distribute not implemented");
    }

    function _register(address[] memory, bytes memory, address) internal virtual override returns (address[] memory) {
        revert("AssuranceContract: Register not implemented");
    }

    // Function to allow the contract to receive ETH
    receive() external payable override {}
}

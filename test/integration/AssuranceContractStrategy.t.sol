// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {AssuranceContract} from "../../contracts/strategies/examples/assurance-contract/AssuranceContract.sol";
import {Metadata} from "../../contracts/core/libraries/Metadata.sol";
import {IAllo} from "../../contracts/core/interfaces/IAllo.sol";
import {IBaseStrategy} from "../../contracts/strategies/IBaseStrategy.sol";

contract AssuranceContractStrategyTest is Test {
    AssuranceContract public assuranceContract;

    address public beneficiary;
    address public contributor1;
    address public contributor2;
    address public mockAllo;

    uint256 public poolId;
    uint256 public goal;
    uint256 public deadline;

    // Define events
    event CampaignCreated(uint256 indexed campaignId, uint256 goal, uint256 deadline, address beneficiary);
    event Pledged(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event GoalReached(uint256 indexed campaignId);
    event FundsClaimed(uint256 indexed campaignId, address beneficiary, uint256 amount);
    event FundsRefunded(uint256 indexed campaignId, address contributor, uint256 amount);

    function setUp() public {
        mockAllo = address(this);
        assuranceContract = new AssuranceContract(mockAllo);

        beneficiary = makeAddr("beneficiary");
        contributor1 = makeAddr("contributor1");
        contributor2 = makeAddr("contributor2");

        poolId = 1;
        goal = 10 ether;
        deadline = block.timestamp + 1 days;
    }

    function test_initialize() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary);
        vm.expectEmit(true, true, true, true);
        emit CampaignCreated(poolId, goal, deadline, beneficiary);
        assuranceContract.initialize(poolId, initData);

        (uint256 _goal, uint256 _totalPledged, uint256 _deadline, address _beneficiary, bool _finalized) = assuranceContract.campaigns(poolId);
        assertEq(_goal, goal);
        assertEq(_totalPledged, 0);
        assertEq(_deadline, deadline);
        assertEq(_beneficiary, beneficiary);
        assertFalse(_finalized);
    }

    function test_pledge() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary);
        assuranceContract.initialize(poolId, initData);

        uint256 pledgeAmount = 1 ether;
        vm.deal(contributor1, pledgeAmount);
        vm.prank(contributor1);
        vm.expectEmit(true, true, true, true);
        emit Pledged(poolId, contributor1, pledgeAmount);
        assuranceContract.pledge{value: pledgeAmount}(poolId);

        assertEq(assuranceContract.pledges(poolId, contributor1), pledgeAmount);
    }

    function test_pledge_reachesGoal() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary);
        assuranceContract.initialize(poolId, initData);

        vm.deal(contributor1, goal);
        vm.prank(contributor1);
        vm.expectEmit(true, true, true, true);
        emit GoalReached(poolId);
        assuranceContract.pledge{value: goal}(poolId);
    }

    function test_pledge_afterDeadline() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary);
        assuranceContract.initialize(poolId, initData);

        vm.warp(deadline + 1);
        vm.deal(contributor1, 1 ether);
        vm.prank(contributor1);
        vm.expectRevert("Campaign ended");
        assuranceContract.pledge{value: 1 ether}(poolId);
    }

    function test_claimFunds() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary);
        assuranceContract.initialize(poolId, initData);

        vm.deal(contributor1, goal);
        vm.prank(contributor1);
        assuranceContract.pledge{value: goal}(poolId);

        vm.warp(deadline + 1);
        vm.prank(beneficiary);
        vm.expectEmit(true, true, true, true);
        emit FundsClaimed(poolId, beneficiary, goal);
        assuranceContract.claimFunds(poolId);

        assertEq(beneficiary.balance, goal);
    }

    function test_refund() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary);
        assuranceContract.initialize(poolId, initData);

        uint256 pledgeAmount = 1 ether;
        vm.deal(contributor1, pledgeAmount);
        vm.prank(contributor1);
        assuranceContract.pledge{value: pledgeAmount}(poolId);

        vm.warp(deadline + 1);
        vm.prank(contributor1);
        vm.expectEmit(true, true, true, true);
        emit FundsRefunded(poolId, contributor1, pledgeAmount);
        assuranceContract.refund(poolId);

        assertEq(contributor1.balance, pledgeAmount);
        assertEq(assuranceContract.pledges(poolId, contributor1), 0);
    }

    function test_claimFunds_beforeDeadline() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary);
        assuranceContract.initialize(poolId, initData);

        vm.deal(contributor1, goal);
        vm.prank(contributor1);
        assuranceContract.pledge{value: goal}(poolId);

        vm.prank(beneficiary);
        vm.expectRevert("Campaign not ended");
        assuranceContract.claimFunds(poolId);
    }

    function test_refund_beforeDeadline() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary);
        assuranceContract.initialize(poolId, initData);

        uint256 pledgeAmount = 1 ether;
        vm.deal(contributor1, pledgeAmount);
        vm.prank(contributor1);
        assuranceContract.pledge{value: pledgeAmount}(poolId);

        vm.prank(contributor1);
        vm.expectRevert("Campaign not ended");
        assuranceContract.refund(poolId);
    }

    // Mock functions to satisfy IAllo interface
    function getPool(uint256) external view returns (IAllo.Pool memory) {
        return IAllo.Pool({
            profileId: bytes32(0),
            strategy: IBaseStrategy(address(0)),
            token: address(0),
            metadata: Metadata(0, ""),
            managerRole: bytes32(0),
            adminRole: bytes32(0)
        });
    }
}

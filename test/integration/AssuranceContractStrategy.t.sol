// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {AssuranceContract} from "../../contracts/strategies/examples/assurance-contract/AssuranceContract.sol";
import {BaseStrategy} from "../../contracts/strategies/BaseStrategy.sol";
import {Metadata} from "../../contracts/core/libraries/Metadata.sol";
import {IAllo} from "../../contracts/core/interfaces/IAllo.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {IBaseStrategy} from "../../contracts/strategies/IBaseStrategy.sol";

contract AssuranceContractStrategyTest is Test {
    AssuranceContract public assuranceContract;
    MockERC20 public mockToken;

    address public beneficiary;
    address public contributor1;
    address public contributor2;
    address public mockAllo;

    uint256 public poolId;
    uint256 public goal;
    uint256 public deadline;

    event CampaignCreated(uint256 indexed poolId, uint256 goal, uint256 deadline, address beneficiary, address tokenAddress);
    event Pledged(uint256 indexed poolId, address indexed contributor, uint256 amount);
    event GoalReached(uint256 indexed poolId);
    event FundsClaimed(uint256 indexed poolId, address beneficiary, uint256 amount);
    event FundsRefunded(uint256 indexed poolId, address contributor, uint256 amount);

    function setUp() public {
        mockAllo = address(this);
        assuranceContract = new AssuranceContract(mockAllo);
        mockToken = new MockERC20("Mock Token", "MTK", 18);

        beneficiary = makeAddr("beneficiary");
        contributor1 = makeAddr("contributor1");
        contributor2 = makeAddr("contributor2");

        poolId = 1;
        goal = 10 ether;
        deadline = block.timestamp + 1 days;
    }

    function testInitializeETH() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary, address(0));
        vm.expectEmit(true, true, true, true);
        emit CampaignCreated(poolId, goal, deadline, beneficiary, address(0));
        assuranceContract.initialize(poolId, initData);

        (uint256 _goal, uint256 _totalPledged, uint256 _deadline, address _beneficiary, bool _finalized, address _tokenAddress) = assuranceContract.campaigns(poolId);
        assertEq(_goal, goal);
        assertEq(_totalPledged, 0);
        assertEq(_deadline, deadline);
        assertEq(_beneficiary, beneficiary);
        assertFalse(_finalized);
        assertEq(_tokenAddress, address(0));
    }

    function testInitializeERC20() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary, address(mockToken));
        vm.expectEmit(true, true, true, true);
        emit CampaignCreated(poolId, goal, deadline, beneficiary, address(mockToken));
        assuranceContract.initialize(poolId, initData);

        (uint256 _goal, uint256 _totalPledged, uint256 _deadline, address _beneficiary, bool _finalized, address _tokenAddress) = assuranceContract.campaigns(poolId);
        assertEq(_goal, goal);
        assertEq(_totalPledged, 0);
        assertEq(_deadline, deadline);
        assertEq(_beneficiary, beneficiary);
        assertFalse(_finalized);
        assertEq(_tokenAddress, address(mockToken));
    }

    function testPledgeETH() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary, address(0));
        assuranceContract.initialize(poolId, initData);

        uint256 pledgeAmount = 1 ether;
        vm.deal(contributor1, pledgeAmount);
        vm.prank(contributor1);
        vm.expectEmit(true, true, true, true);
        emit Pledged(poolId, contributor1, pledgeAmount);
        assuranceContract.pledge{value: pledgeAmount}(poolId, pledgeAmount);

        assertEq(assuranceContract.pledges(poolId, contributor1), pledgeAmount);
    }

    function testPledgeERC20() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary, address(mockToken));
        assuranceContract.initialize(poolId, initData);

        uint256 pledgeAmount = 1 ether;
        mockToken.mint(contributor1, pledgeAmount);
        vm.startPrank(contributor1);
        mockToken.approve(address(assuranceContract), pledgeAmount);
        vm.expectEmit(true, true, true, true);
        emit Pledged(poolId, contributor1, pledgeAmount);
        assuranceContract.pledge(poolId, pledgeAmount);
        vm.stopPrank();

        assertEq(assuranceContract.pledges(poolId, contributor1), pledgeAmount);
    }

    function testClaimFundsETH() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary, address(0));
        assuranceContract.initialize(poolId, initData);

        vm.deal(contributor1, goal);
        vm.prank(contributor1);
        assuranceContract.pledge{value: goal}(poolId, goal);
        
        vm.warp(deadline + 1);
        vm.prank(beneficiary);
        vm.expectEmit(true, true, true, true);
        emit FundsClaimed(poolId, beneficiary, goal);
        assuranceContract.claimFunds(poolId);

        assertEq(beneficiary.balance, goal);
    }

    function testClaimFundsERC20() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary, address(mockToken));
        assuranceContract.initialize(poolId, initData);

        mockToken.mint(contributor1, goal);
        vm.startPrank(contributor1);
        mockToken.approve(address(assuranceContract), goal);
        assuranceContract.pledge(poolId, goal);
        vm.stopPrank();
        
        vm.warp(deadline + 1);
        vm.prank(beneficiary);
        vm.expectEmit(true, true, true, true);
        emit FundsClaimed(poolId, beneficiary, goal);
        assuranceContract.claimFunds(poolId);

        assertEq(mockToken.balanceOf(beneficiary), goal);
    }

    function testRefundETH() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary, address(0));
        assuranceContract.initialize(poolId, initData);

        uint256 pledgeAmount = 1 ether;
        vm.deal(contributor1, pledgeAmount);
        vm.prank(contributor1);
        assuranceContract.pledge{value: pledgeAmount}(poolId, pledgeAmount);

        vm.warp(deadline + 1);
        vm.prank(contributor1);
        vm.expectEmit(true, true, true, true);
        emit FundsRefunded(poolId, contributor1, pledgeAmount);
        assuranceContract.refund(poolId);

        assertEq(contributor1.balance, pledgeAmount);
        assertEq(assuranceContract.pledges(poolId, contributor1), 0);
    }

    function testRefundERC20() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary, address(mockToken));
        assuranceContract.initialize(poolId, initData);

        uint256 pledgeAmount = 1 ether;
        mockToken.mint(contributor1, pledgeAmount);
        vm.startPrank(contributor1);
        mockToken.approve(address(assuranceContract), pledgeAmount);
        assuranceContract.pledge(poolId, pledgeAmount);
        vm.stopPrank();

        vm.warp(deadline + 1);
        vm.prank(contributor1);
        vm.expectEmit(true, true, true, true);
        emit FundsRefunded(poolId, contributor1, pledgeAmount);
        assuranceContract.refund(poolId);

        assertEq(mockToken.balanceOf(contributor1), pledgeAmount);
        assertEq(assuranceContract.pledges(poolId, contributor1), 0);
    }

    function testPledgeAfterDeadline() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary, address(0));
        assuranceContract.initialize(poolId, initData);

        vm.warp(deadline + 1);
        vm.deal(contributor1, 1 ether);
        vm.prank(contributor1);
        assuranceContract.pledge{value: 1 ether}(poolId, 1 ether);
    }

    function testClaimFundsBeforeDeadline() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary, address(0));
        assuranceContract.initialize(poolId, initData);

        vm.deal(contributor1, goal);
        vm.prank(contributor1);
        assuranceContract.pledge{value: goal}(poolId, goal);

        vm.prank(beneficiary);
        vm.expectRevert("Campaign not ended");
        assuranceContract.claimFunds(poolId);
    }

    function testRefundBeforeDeadline() public {
        bytes memory initData = abi.encode(goal, deadline, beneficiary, address(0));
        assuranceContract.initialize(poolId, initData);

        uint256 pledgeAmount = 1 ether;
        vm.deal(contributor1, pledgeAmount);
        vm.prank(contributor1);
        assuranceContract.pledge{value: pledgeAmount}(poolId, pledgeAmount);

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

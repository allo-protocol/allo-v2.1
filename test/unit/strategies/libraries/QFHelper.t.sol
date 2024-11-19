/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/// import forge-std/Test.sol
import "forge-std/Test.sol";
/// import Mock Contract
import "test/mocks/MockQFHelper.sol";
import "strategies/libraries/QFHelper.sol";

contract MockQFHelperTest is Test {
    MockQFHelper public mockQFHelper;

    address public funder = makeAddr("funder");
    address[] public recipient1 = new address[](1);
    address[] public recipient2 = new address[](1);
    uint256[] public donation1 = new uint256[](1);
    uint256[] public donation2 = new uint256[](1);
    uint256 public constant DONATION_1 = 1;
    uint256 public constant DONATION_2 = 100;
    uint256 public constant MATCHING_AMOUNT = 1000;

    function setUp() public {
        mockQFHelper = new MockQFHelper();

        recipient1[0] = makeAddr("recipient1");
        recipient2[0] = makeAddr("recipient2");
        donation1[0] = DONATION_1;
        donation2[0] = DONATION_2;
    }

    function test_FundRevertWhen_InputArraysMissmatch(address[] memory _recipients, uint256[] memory _amounts)
        external
    {
        vm.assume(_recipients.length != _amounts.length);

        // it should revert
        vm.expectRevert(QFHelper.QFHelper_LengthMissmatch.selector);
        mockQFHelper.fund(_recipients, _amounts);
    }

    function test_FundWhenInputArraysMatch() external {
        /// Fund more than one recipient at a time
        uint256[] memory _donations = new uint256[](2);
        _donations[0] = DONATION_1;
        _donations[1] = DONATION_2;

        address[] memory _recipients = new address[](2);
        _recipients[0] = recipient1[0];
        _recipients[1] = recipient2[0];

        assertEq(mockQFHelper.getTotalContributions(), 0);
        vm.prank(funder);
        mockQFHelper.fund(_recipients, _donations);

        // it should call fundSingle
        assertGt(mockQFHelper.getTotalContributions(), 0);
    }

    function test_FundSingleShouldUpdateTheSqrtDonationsSumOfTheRecipient(address _recipient, uint256 _amount)
        external
    {
        vm.assume(_recipient != address(0));
        _amount = bound(_amount, 1, 100 ether);

        assertEq(mockQFHelper.getSqrtDonationsSum(_recipient), 0);
        mockQFHelper.fundSingle(_recipient, _amount);
        // it should update the sqrtDonationsSum of the recipient
        assertEq(mockQFHelper.getSqrtDonationsSum(_recipient), FixedPointMathLib.sqrt(_amount));
    }

    function test_FundSingleShouldUpdateTheTotalContributions(address _recipient, uint256 _amount) external {
        vm.assume(_recipient != address(0));
        _amount = bound(_amount, 1, 100 ether);

        assertEq(mockQFHelper.getTotalContributions(), 0);
        mockQFHelper.fundSingle(_recipient, _amount);
        // it should update the total contributions
        assertEq(mockQFHelper.getTotalContributions(), FixedPointMathLib.sqrt(_amount) ** 2);
    }

    function test_CalculateMatchingShouldReturnTheMatchingAmountForTheRecipient() external {
        /// Custom donation amounts
        for (uint256 i = 0; i < 5; i++) {
            /// Donate 5 times to recipient 1, 1 amount
            mockQFHelper.fund(recipient1, donation1);
        }
        /// Donate 1 time to recipient 2, 100 amount
        mockQFHelper.fund(recipient2, donation2);

        /// Total contributions should be 125
        /// (5 * sqrt(1))^2 + (1 * sqrt(100))^2 = 125
        assertEq(mockQFHelper.getTotalContributions(), 125);

        uint256 _firstRecipientMatchingAmount = mockQFHelper.getCalcuateMatchingAmount(MATCHING_AMOUNT, recipient1[0]);
        uint256 _secondRecipientMatchingAmount = mockQFHelper.getCalcuateMatchingAmount(MATCHING_AMOUNT, recipient2[0]);

        /// Based on this example https://qf.gitcoin.co/?grant=1,1,1,1,1&grant=100&grant=&grant=&match=1000
        /// the payout should be 200 for recipient 1 and 800 for recipient 2
        // it should return the matching amount for the recipient
        assertEq(_firstRecipientMatchingAmount, 200);
        assertEq(_secondRecipientMatchingAmount, 800);
    }
}

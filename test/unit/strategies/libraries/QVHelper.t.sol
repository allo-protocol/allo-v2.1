/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/// import forge-std/Test.sol
import "forge-std/Test.sol";
/// import Mock Contract
import "test/mocks/MockQVHelper.sol";
import "strategies/libraries/QVHelper.sol";

contract MockQVHelperTest is Test {
    MockQVHelper public mockQVHelper;

    address public recipient1 = makeAddr("recipient1");
    address public recipient2 = makeAddr("recipient2");
    uint256 public constant POOL_BALANCE = 100;

    function setUp() public {
        mockQVHelper = new MockQVHelper();
    }

    function test_VoteWithVoiceCreditsRevertWhen_InputArraysMissmatch() external {
        address[] memory _recipients = new address[](1);
        _recipients[0] = recipient1;

        uint256[] memory _voiceCredits = new uint256[](2);
        _voiceCredits[0] = 1;
        _voiceCredits[1] = 2;

        vm.expectRevert(QVHelper.QVHelper_LengthMissmatch.selector);
        mockQVHelper.voteWithCredits(_recipients, _voiceCredits);
    }

    function test_VoteWithVoiceCreditsWhenInputArraysMatch() external {
        address[] memory _recipients = new address[](2);
        _recipients[0] = recipient1;
        _recipients[1] = recipient2;

        uint256[] memory _voiceCredits = new uint256[](2);
        _voiceCredits[0] = 1;
        _voiceCredits[1] = 2;

        mockQVHelper.voteWithCredits(_recipients, _voiceCredits);

        // it should call voteSingleWithVoiceCredits
        assertEq(mockQVHelper.getVoiceCredits(_recipients[0]), 1);
        assertEq(mockQVHelper.getVoiceCredits(_recipients[1]), 2);
    }

    function test_VoteSingleWithVoiceCreditsShouldUpdateTheRecipientsVoiceCredits(
        address _recipient,
        uint256 _voiceCredits
    ) external {
        vm.assume(_recipient != address(0));
        _voiceCredits = bound(_voiceCredits, 1, 1000);

        assertEq(mockQVHelper.getVoiceCredits(_recipient), 0);
        mockQVHelper.voteSingleWithCredits(_recipient, _voiceCredits);
        // it should aupdate the recipients voice credits
        assertEq(mockQVHelper.getVoiceCredits(_recipient), _voiceCredits);
    }

    function test_VoteSingleWithVoiceCreditsShouldUpdateTheRecipientsVotes(address _recipient, uint256 _voiceCredits)
        external
    {
        vm.assume(_recipient != address(0));
        _voiceCredits = bound(_voiceCredits, 1, 1000);

        assertEq(mockQVHelper.getVotes(_recipient), 0);
        mockQVHelper.voteSingleWithCredits(_recipient, _voiceCredits);
        // it should update the recipients votes
        assertEq(mockQVHelper.getVotes(_recipient), FixedPointMathLib.sqrt(_voiceCredits));
    }

    function test_VoteSingleWithVoiceCreditsShouldUpdateTheTotalVoiceCredits(address _recipient, uint256 _voiceCredits)
        external
    {
        vm.assume(_recipient != address(0));
        _voiceCredits = bound(_voiceCredits, 1, 1000);

        assertEq(mockQVHelper.getTotalVoiceCredits(), 0);
        mockQVHelper.voteSingleWithCredits(_recipient, _voiceCredits);
        // it should update the total voice credits
        assertEq(mockQVHelper.getTotalVoiceCredits(), _voiceCredits);
    }

    function test_VoteSingleWithVoiceCreditsShouldUpdateTheTotalVotes(address _recipient, uint256 _voiceCredits)
        external
    {
        vm.assume(_recipient != address(0));
        _voiceCredits = bound(_voiceCredits, 1, 1000);

        assertEq(mockQVHelper.getTotalVotes(), 0);
        mockQVHelper.voteSingleWithCredits(_recipient, _voiceCredits);
        // it should update the total votes
        assertEq(mockQVHelper.getTotalVotes(), FixedPointMathLib.sqrt(_voiceCredits));
    }

    function test_VoteRevertWhen_InputArraysMissmatch(address[] memory _recipients, uint256[] memory _votes) external {
        vm.assume(_recipients.length != _votes.length);

        // it should revert
        vm.expectRevert(QVHelper.QVHelper_LengthMissmatch.selector);
        mockQVHelper.vote(_recipients, _votes);
    }

    function test_VoteWhenInputArraysMatch() external {
        address[] memory _recipients = new address[](2);
        _recipients[0] = recipient1;
        _recipients[1] = recipient2;

        uint256[] memory _votes = new uint256[](2);
        _votes[0] = 1;
        _votes[1] = 2;

        mockQVHelper.vote(_recipients, _votes);

        assertEq(mockQVHelper.getVotes(_recipients[0]), 1);
        assertEq(mockQVHelper.getVotes(_recipients[1]), 2);
    }

    function test_VoteSingleShouldAupdateTheRecipientsVoiceCredits(address _recipient, uint256 _votes) external {
        vm.assume(_recipient != address(0));
        _votes = bound(_votes, 1, 1000);

        assertEq(mockQVHelper.getVoiceCredits(_recipient), 0);
        mockQVHelper.voteSingle(_recipient, _votes);
        // it should aupdate the recipients voice credits
        assertEq(mockQVHelper.getVoiceCredits(_recipient), _votes ** 2);
    }

    function test_VoteSingleShouldUpdateTheRecipientsVotes(address _recipient, uint256 _votes) external {
        vm.assume(_recipient != address(0));
        _votes = bound(_votes, 1, 1000);

        assertEq(mockQVHelper.getVotes(_recipient), 0);
        mockQVHelper.voteSingle(_recipient, _votes);
        // it should update the recipients votes
        assertEq(mockQVHelper.getVotes(_recipient), _votes);
    }

    function test_VoteSingleShouldUpdateTheTotalVoiceCredits(address _recipient, uint256 _votes) external {
        vm.assume(_recipient != address(0));
        _votes = bound(_votes, 1, 1000);

        assertEq(mockQVHelper.getTotalVoiceCredits(), 0);
        mockQVHelper.voteSingle(_recipient, _votes);
        // it should update the total voice credits
        assertEq(mockQVHelper.getTotalVoiceCredits(), _votes ** 2);
    }

    function test_VoteSingleShouldUpdateTheTotalVotes(address _recipient, uint256 _votes) external {
        vm.assume(_recipient != address(0));
        _votes = bound(_votes, 1, 1000);

        assertEq(mockQVHelper.getTotalVotes(), 0);
        mockQVHelper.voteSingle(_recipient, _votes);
        // it should update the total votes
        assertEq(mockQVHelper.getTotalVotes(), _votes);
    }

    function test_GetPayoutShouldReturnThePayoutForEachRecipient() external {
        address[] memory _recipients = new address[](2);
        _recipients[0] = recipient1;
        _recipients[1] = recipient2;

        uint256[] memory _votes = new uint256[](2);
        _votes[0] = 1;
        _votes[1] = 2;

        mockQVHelper.vote(_recipients, _votes);

        (uint256[] memory _payouts) = mockQVHelper.getPayoutAmount(_recipients, POOL_BALANCE);

        // it should return the payout for each recipient
        assertEq(_payouts[0], 33);
        assertEq(_payouts[1], 66);
    }
}

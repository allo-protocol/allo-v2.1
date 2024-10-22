import {Metadata} from "contracts/core/libraries/Metadata.sol";

contract ProfileBountiesStorage {
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
        // maybe recipientAddress?
    }

    /// ===============================
    /// ========== Storage ============
    /// ===============================

    /// @notice Counter for the number of bounties created
    uint256 public bountyIdCounter;

    /// @notice Mapping of bounty id to bounty
    mapping(uint256 => Bounty) public bounties;

    /// @notice Mapping of bounty id to recipientAddress to bounty application
    mapping(uint256 => mapping(address => BountyApplication)) public bountyApplications;
}

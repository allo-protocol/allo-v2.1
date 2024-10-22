import {Metadata} from "contracts/core/libraries/Metadata.sol";

contract ProfileBountiesStorage {

    struct Bounty {
        address token;
        uint256 amount;
        Metadata metadata;
        // status
    }

    /// ===============================
    /// ========== Storage ============
    /// ===============================

    /// @notice Counter for the number of bounties created
    uint256 public bountyIdCounter;

    /// @notice Mapping of bounty id to bounty
    mapping(uint256 => Bounty) public bounties;

}
pragma solidity ^0.8.19;

contract GhostStorage {
    uint256[] internal ghost_poolIds;
    mapping(uint256 _poolId => address _poolAdmin) internal ghost_poolAdmins;
    mapping(uint256 _poolId => address[] _managers) ghost_poolManagers;

    uint256 numberOfActors = 6;
    address[] internal _ghost_actors;

    mapping(address actor => address anchor) internal _ghost_anchorOf;

    mapping(uint256 _poolId => address[] _recipients) ghost_recipients;

    uint256 ghost_totalReceived; // only net amounts, after fee (direct transfer)
    uint256 ghost_availableToAllocate;
    uint256 ghost_totalAllocatedNotDistributed;
    uint256 ghost_totalWithdrawn;

    uint256 internal _ghost_nonce;
    bytes32[] internal _ghost_pendingOwnershipChange;
    mapping(bytes32 _profileId => address[] _members)
        internal _ghost_roleMembers;
}

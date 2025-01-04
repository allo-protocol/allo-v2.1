pragma solidity ^0.8.19;

contract GhostStorage {
    uint256[] ghost_poolIds;
    mapping(uint256 _poolId => address _poolAdmin) ghost_poolAdmins;
    mapping(uint256 _poolId => address[] _managers) ghost_poolManagers;

    uint256 numberOfActors = 10;
    address[] _ghost_actors;

    mapping(address actor => address anchor) _ghost_anchorOf;

    mapping(uint256 _poolId => address[] _recipients) ghost_recipients;

    uint256 ghost_totalReceived; // only net amounts, after fee (direct transfer)
    uint256 ghost_availableToAllocate;
    uint256 ghost_totalAllocatedNotDistributed;
    uint256 ghost_totalWithdrawn;

    uint256 _ghost_nonce;
    bytes32[] _ghost_pendingOwnershipChange;
    mapping(bytes32 _profileId => address[] _members) _ghost_roleMembers;
}

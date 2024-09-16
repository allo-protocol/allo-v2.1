// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {Anchor} from "contracts/core/Anchor.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";

contract AnchorUnit is Test {
    function test_ConstructorShouldSetRegistry(bytes32 _profileId, address _registry) external {
        // it should set registry
        Anchor anchor = new Anchor(_profileId, _registry);
        assertEq(address(anchor.registry()), _registry);
    }

    function test_ConstructorShouldSetProfileId(bytes32 _profileId, address _registry) external {
        // it should set profileId
        Anchor anchor = new Anchor(_profileId, _registry);
        assertEq(anchor.profileId(), _profileId);
    }

    function test_ExecuteRevertWhen_CallerIsNotTheProfileIdOwner() external {
        // it should revert
    }

    function test_ExecuteRevertWhen__targetIsTheZeroAddress() external {
        // it should revert
    }

    modifier whenCallerOwnsTheProfile() {
        _;
    }

    modifier when_targetIsNotTheZeroAddress() {
        _;
    }

    function test_ExecuteRevertWhen_TheCallTo_targetFails()
        external
        whenCallerOwnsTheProfile
        when_targetIsNotTheZeroAddress
    {
        // it should revert
    }

    function test_ExecuteWhenTheCallTo_targetSucceeds()
        external
        whenCallerOwnsTheProfile
        when_targetIsNotTheZeroAddress
    {
        // it should return the data returned by the call
        // it should call _target with _value and _data
    }

    function test_ReceiveShouldReceiveNativeTokens() external {
        // it should receive native tokens
    }

    function test_Erc721HolderShouldReturnTheOnERC721ReceivedSelector() external {
        // it should return the onERC721Received selector
    }

    function test_Erc1155HolderShouldReturnTheOnERC1155ReceivedSelector() external {
        // it should return the onERC1155Received selector
    }

    function test_Erc1155HolderBatchShouldReturnTheOnERC1155BatchReceivedSelector() external {
        // it should return the onERC1155BatchReceived selector
    }
}

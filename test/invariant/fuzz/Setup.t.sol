// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {Allo, IAllo, Metadata} from "contracts/core/Allo.sol";
import {Registry, Anchor} from "contracts/core/Anchor.sol";
import {IRegistry} from "contracts/core/interfaces/IRegistry.sol";
import {DirectAllocationStrategy} from "contracts/strategies/examples/direct-allocation/DirectAllocation.sol";
import {QVSimple} from "contracts/strategies/examples/quadratic-voting/QVSimple.sol";
import {SQFSuperfluid} from "contracts/strategies/examples/sqf-superfluid/SQFSuperfluid.sol";

import {IRecipientsExtension} from "strategies/extensions/register/IRecipientsExtension.sol";

import {HandlerActors, Actors} from "./helpers/Actors.t.sol";
import {Pools} from "./helpers/Pools.t.sol";
import {Utils} from "./helpers/Utils.t.sol";
import {FuzzERC20, ERC20} from "./helpers/FuzzERC20.sol";

contract Setup is HandlerActors, Pools {
    uint256 percentFee;
    uint256 baseFee;

    uint64 defaultRegistrationStartTime;
    uint64 defaultRegistrationEndTime;
    uint256 defaultAllocationStartTime;
    uint256 defaultAllocationEndTime;
    uint256 defaultWithdrawalCooldown;
    uint256 DEFAULT_MAX_BID;

    Allo allo;
    Registry registry;

    ERC20 token;

    address protocolDeployer = makeAddr("protocolDeployer");
    address proxyOwner = makeAddr("proxyOwner");
    address treasury = makeAddr("treasury");
    address forwarder = makeAddr("forwarder");

    constructor() {
        // Deploy Allo
        address implementation = address(new Allo());

        // Deploy the registry
        registry = new Registry();

        // Deploy the proxy, pointing to the implementation
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            implementation,
            proxyOwner,
            ""
        );

        allo = Allo(payable(address(proxy)));

        // Initialize
        allo.initialize(
            protocolDeployer,
            address(registry),
            payable(treasury),
            percentFee,
            baseFee,
            forwarder
        );

        // Deploy strategies implementations
        _initImplementations(address(allo));

        // Deploy token
        token = ERC20(address(new FuzzERC20()));

        // Deploy actors, create profile for all actors, add a
        // member to each profile
        for (uint256 i; i < numberOfActors; i++) {
            Actors _newActor = new Actors();

            bytes32 _id = registry.createProfile(
                0,
                "a",
                Metadata({protocol: i + 1, pointer: ""}),
                address(_newActor),
                new address[](0)
            );

            _newActor.changeAnchor(registry.getProfileById(_id).anchor);

            _ghost_actors.push(address(_newActor));
        }

        // Create pools for each strategy
        _initPools();
    }

    function _initPools() internal {
        defaultRegistrationStartTime = uint64(block.timestamp);
        defaultRegistrationEndTime = uint64(block.timestamp + 7 days);
        defaultAllocationStartTime = uint64(block.timestamp + 7 days + 1);
        defaultAllocationEndTime = uint64(block.timestamp + 10 days);
        defaultWithdrawalCooldown = 1 days;
        DEFAULT_MAX_BID = 1000;

        for (uint256 i; i <= uint256(type(PoolStrategies).max); i++) {
            Actors _deployer = Actors(payable(_ghost_actors[i]));
            IRegistry.Profile memory profile = registry.getProfileByAnchor(
                _deployer.controlledAnchor()
            );

            bytes memory _metadata;

            if (PoolStrategies(i) == PoolStrategies.FuzzBaseStrategy) {
                _metadata = "";
            } else if (PoolStrategies(i) == PoolStrategies.DirectAllocation) {
                _metadata = "";
            } else if (PoolStrategies(i) == PoolStrategies.DonationVoting) {
                _metadata = abi.encode(
                    IRecipientsExtension.RecipientInitializeData({
                        metadataRequired: false,
                        registrationStartTime: defaultRegistrationStartTime,
                        registrationEndTime: defaultRegistrationEndTime
                    }),
                    defaultAllocationStartTime,
                    defaultAllocationEndTime,
                    defaultWithdrawalCooldown,
                    token,
                    true
                );
            } else if (
                PoolStrategies(i) == PoolStrategies.EasyRPGF
            ) {} else if (PoolStrategies(i) == PoolStrategies.ImpactStream) {
                _metadata = abi.encode(
                    IRecipientsExtension.RecipientInitializeData({
                        metadataRequired: false,
                        registrationStartTime: uint64(block.timestamp),
                        registrationEndTime: uint64(block.timestamp + 7 days)
                    }),
                    QVSimple.QVSimpleInitializeData({
                        allocationStartTime: uint64(block.timestamp),
                        allocationEndTime: uint64(block.timestamp + 7 days),
                        maxVoiceCreditsPerAllocator: 100,
                        isUsingAllocationMetadata: false
                    })
                );
            } else if (PoolStrategies(i) == PoolStrategies.QuadraticVoting) {
                _metadata = abi.encode(
                    IRecipientsExtension.RecipientInitializeData({
                        metadataRequired: false,
                        registrationStartTime: uint64(block.timestamp),
                        registrationEndTime: uint64(block.timestamp + 7 days)
                    }),
                    QVSimple.QVSimpleInitializeData({
                        allocationStartTime: uint64(block.timestamp),
                        allocationEndTime: uint64(block.timestamp + 7 days),
                        maxVoiceCreditsPerAllocator: 100,
                        isUsingAllocationMetadata: false
                    })
                );
            } else if (PoolStrategies(i) == PoolStrategies.RFP) {
                _metadata = abi.encode(
                    IRecipientsExtension.RecipientInitializeData({
                        metadataRequired: false,
                        registrationStartTime: uint64(block.timestamp),
                        registrationEndTime: uint64(block.timestamp + 7 days)
                    }),
                    DEFAULT_MAX_BID
                );
            } else if (PoolStrategies(i) == PoolStrategies.SQFSuperfluid) {
                // Skip for now - mock?
                return;
            }

            address[] memory managers = new address[](1);
            managers[0] = address(_deployer.controlledAnchor());

            (bool succ, bytes memory ret) = _deployer.directCall(
                address(allo),
                0,
                abi.encodeCall(
                    allo.createPool,
                    (
                        profile.id,
                        _strategyImplementations[PoolStrategies(i)],
                        _metadata,
                        address(token),
                        0,
                        profile.metadata,
                        managers
                    )
                )
            );

            if (!succ) {
                revert("Failed to create pool");
            }

            uint256 _poolId = abi.decode(ret, (uint256));

            // Update the implementation used (as it's cloned)
            _strategyImplementations[PoolStrategies(i)] = allo.getStrategy(
                _poolId
            );

            ghost_poolAdmins[_poolId] = address(_deployer);
            ghost_poolManagers[_poolId].push(managers[0]);

            assertTrue(
                allo.isPoolAdmin(_poolId, address(_deployer)),
                "Admin not set _initPools_"
            );

            assertTrue(
                allo.isPoolManager(_poolId, managers[0]),
                "Manager not set _initPools_"
            );

            _recordPool(_poolId);
        }
    }
}

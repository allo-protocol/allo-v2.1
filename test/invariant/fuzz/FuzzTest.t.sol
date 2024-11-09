// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {PropertiesParent} from "./properties/PropertiesParent.t.sol";

contract FuzzTest is PropertiesParent {
    /// @custom:property-id 0
    /// @custom:property Check sanity
    function property_sanityCheck() public {
        assertTrue(address(allo) != address(0), "sanity check");
        assertTrue(address(registry) != address(0), "sanity check");
        assertEq(address(treasury), allo.getTreasury(), "sanity check");
        assertEq(percentFee, allo.getPercentFee(), "sanity check");
        assertEq(baseFee, allo.getBaseFee(), "sanity check");
        assertTrue(allo.isTrustedForwarder(forwarder), "sanity check");
    }

    function test_debug() public {
        vm.prank(0x0000000000000000000000000000000000060000);
        vm.warp(363880);
        vm.roll(7847);
        this.prop_onlyProfileOwnerCanAddProfileMember(
            60631582292742362849026949271476756118785624581464653091202846223898848146691,
            89282359687353882127807534269204883388438548566703146330431871473520306843085
        );

        vm.prank(0x0000000000000000000000000000000000020000);
        vm.warp(724500);
        vm.roll(46047);
        this.prop_profileOwnerCanAlwaysCreateAPool(
            0,
            32210232866365689975362222313107238028207728485110902278053676665585564356325
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {Transfer} from "contracts/core/libraries/Transfer.sol";

import {HandlersParent} from "../handlers/HandlersParent.t.sol";
import {IAllo, Allo, Metadata} from "contracts/core/Allo.sol";
import {IRegistry, Registry} from "contracts/core/Registry.sol";
import {IBaseStrategy} from "contracts/strategies/BaseStrategy.sol";

import {Errors} from "contracts/core/libraries/Errors.sol";

import {FuzzERC20, ERC20} from "../helpers/FuzzERC20.sol";

contract PropertiesAllo is HandlersParent {
    ///@custom:property-id 1-a
    ///@custom:property one should always be able to allocate for recipient
    ///@custom:property-id 1-b
    ///@custom:property one should always be able to pull correct (based on strategy) allocation for recipient
    ///@custom:property-id 2
    ///@custom:property a token allocation never “disappears” (withdraw cannot impact an allocation)
    ///@custom:property-id 3
    ///@custom:property an address can only withdraw if has allocation
    ///@custom:property-id 12
    ///@custom:property pool manager can always withdraw within strategy limits/logic
    ///@custom:property-id 17
    ///@custom:property only funds not allocated can be withdrawn
    ///@custom:property-id 18
    ///@custom:property anyone can increase fund in a pool, if strategy (hook) logic allows so and if more than base fee
}

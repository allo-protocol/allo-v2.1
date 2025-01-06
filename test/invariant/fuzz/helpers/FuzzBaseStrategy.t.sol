/// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {BaseStrategy} from "../../../../contracts/strategies/BaseStrategy.sol";
import {ERC20} from "./FuzzERC20.sol";

// Minimal implementation of the BaseStrategy
contract FuzzBaseStrategy is BaseStrategy {
    address[] public recipients;
    mapping(address => uint256) public allocated;

    constructor(address _allo) BaseStrategy(_allo, "FuzzBaseStrategy") {}

    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        __BaseStrategy_init(_poolId);
        emit Initialized(_poolId, _data);
    }

    function _register(address[] memory _recipients, bytes memory _data, address _sender)
        internal
        override
        returns (address[] memory _recipientIds)
    {
        recipients = _recipients;
        _recipientIds = new address[](_recipients.length);
        for (uint256 i = 0; i < _recipients.length; i++) {
            _recipientIds[i] = _recipients[i];
        }
    }

    function _allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        override
    {
        for (uint256 i = 0; i < _recipients.length; i++) {
            allocated[_recipients[i]] = _amounts[i];
        }
    }

    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal override {
        ERC20 _token = ERC20(_ALLO.getPool(_poolId).token);
        for (uint256 i = 0; i < _recipientIds.length; i++) {
            _token.transfer(_recipientIds[i], allocated[_recipientIds[i]]);
            _poolAmount -= allocated[_recipientIds[i]];
        }
    }
}

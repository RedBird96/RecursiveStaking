// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

abstract contract BasicLogic {
    address public immutable LOGIC_ADDRESS;

    constructor() {
        LOGIC_ADDRESS = address(this);
    }

    modifier onlyDelegation() {
        require(LOGIC_ADDRESS != address(this), "Only for delegatecall.");
        _;
    }
}
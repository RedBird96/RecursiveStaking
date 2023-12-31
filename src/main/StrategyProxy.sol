// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {Proxy} from "../infiniteProxy/proxy.sol";

/**
 * @title StrategyProxy contract
 * @dev This contract is the actual address of the strategy pool, which
 * manages all the assets. The logic of the contract is distributed among
 * various functional modules.
 */
contract StrategyProxy is Proxy {
    constructor(address _admin, address _dummyImplementation) Proxy(_admin, _dummyImplementation) {}
}
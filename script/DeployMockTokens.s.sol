// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MockERC20} from "../src/mock/MockstETH.sol";
import {BaseDeployer} from "./BaseDeployer.s.sol";
import {console} from "lib/forge-std/src/console.sol";

contract DeployMockToken is BaseDeployer {
    MockERC20 public mockstETH;
    MockERC20 public mockwstETH;
    
    function setUp() public {

    }

    function run() external setEnvDeploy(Cycle.Test) broadcast(_deployerPrivateKey) {
        mockstETH = new MockERC20("Mock stETH", "mstETH", 18);
        mockwstETH = new MockERC20("Mock wstETH", "mwstETH", 18);
        console.log("===========================================");
        console.log("Mock stETH", address(mockstETH));
        console.log("Mock wstETH", address(mockwstETH));
        console.log("===========================================");
    }
}
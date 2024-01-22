// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MockStToken} from "../src/mock/MockstETH.sol";
import {MockToken} from "../src/mock/MockERC20.sol";
import {BaseDeployer} from "./BaseDeployer.s.sol";
import {console} from "lib/forge-std/src/console.sol";

contract DeployMockToken is BaseDeployer {
    MockStToken public mockstETH;
    MockStToken public mockwstETH;
    MockToken public mockTokenERC20;
    function setUp() public {
        createSelectFork(Chains.Sepolia);
    }

    function deploystETH()
        external 
        setEnvDeploy(Cycle.Test) 
        broadcast(_deployerPrivateKey) 
    {
        mockstETH = new MockStToken("Mock stETH", "mstETH", 18);
        mockwstETH = new MockStToken("Mock wstETH", "mwstETH", 18);
        console.log("===========================================");
        console.log("Mock stETH", address(mockstETH));
        console.log("Mock wstETH", address(mockwstETH));
        console.log("===========================================");
    }

    function deployERC20()
        external
        setEnvDeploy(Cycle.Test) 
        broadcast(_deployerPrivateKey)
    {
        mockTokenERC20 = new MockToken("Mock wstETH ERC20", "wstETH", 1e18);
        console.log("Mock stETH ERC20", address(mockTokenERC20));
    }

}
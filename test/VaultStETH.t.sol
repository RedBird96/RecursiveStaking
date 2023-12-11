// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {TransparentUpgradeableProxy} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Test} from "lib/forge-std/src/Test.sol";
import {VaultStETH} from "../src/main/VaultStETH.sol";
import {DSTest} from "./utils/DSTest.sol";
import {console} from "./utils/console.sol";

contract VaultStETHTest is DSTest {

    VaultStETH vault;
    VaultStETH vaultProxy;
    TransparentUpgradeableProxy proxy;
    address strategy;
    address feeReceiver;
    address owner;
    uint256 marketCapacity;
    uint256 managementFeePercentage;
    uint256 exitFeeRate;
    uint256 deleverageExitFeeRate;

    function setUp() external {
        vm.createSelectFork("https://arb-mainnet.g.alchemy.com/v2/EBq207Wb2kJF6CGEVSTuliPcwlvU1MtE", 159_058_461);
        
        owner = address(0x7b08155084680478FF44F26986eb0F598D3D5783);
        strategy = address(0xb329504622bd79329c6F82CF8c60c807dF2090c4);
        feeReceiver = address(0x7b08155084680478FF44F26986eb0F598D3D5783);
        marketCapacity = 1000e18;
        managementFeePercentage = 2;
        exitFeeRate = 2;
        deleverageExitFeeRate = 2;

        vm.prank(owner);
        vault = new VaultStETH();
        proxy = new TransparentUpgradeableProxy(address(vault), address(owner), "");
        vaultProxy = VaultStETH(address(proxy));
        vaultProxy.initialize(
            strategy, 
            feeReceiver, 
            marketCapacity, 
            managementFeePercentage, 
            exitFeeRate, 
            deleverageExitFeeRate
        );
    }

    function testConstructor() external {
        assertEq(address(vault.implementationAddress()), address(vault));
    }

    function testUpdateStrategy() external {

        vm.prank(owner);
        vault.updateStrategy(strategy);

    }
}
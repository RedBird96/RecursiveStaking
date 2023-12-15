// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TransparentUpgradeableProxy} from "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Test} from "lib/forge-std/src/Test.sol";
import {VaultStETH} from "../src/main/VaultStETH.sol";
import {StrategyDummyImplementation} from "../src/main/StrategyDummyImplementation.sol";
import {DSTest} from "./utils/DSTest.sol";
import {console} from "./utils/console.sol";

contract VaultStETHTest is DSTest {

    VaultStETH public vault;
    VaultStETH public vaultProxy;
    TransparentUpgradeableProxy public proxy;
    StrategyDummyImplementation public dummyImpl;
    address public strategy;
    address public feeReceiver;
    address public owner;
    uint256 public marketCapacity;
    uint256 public managementFeePercentage;
    uint256 public exitFeeRate;
    uint256 public deleverageExitFeeRate;

    function setUp() external {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/7uuQCPu-lHbOrA_pkmzXWvDfx-aj6DxH", 18_763_842);
        
        owner = address(0x7b08155084680478FF44F26986eb0F598D3D5783);
        strategy = address(0x3fD49A8F37E2349A29EA701b56F10f03B08F1532);
        feeReceiver = address(0xAA172dB9612Da4c71009573e5d1Cf17f8d02B50C);
        marketCapacity = 1000e18;
        managementFeePercentage = 2;
        exitFeeRate = 2;
        deleverageExitFeeRate = 2;

        vault = new VaultStETH();
        dummyImpl = new StrategyDummyImplementation();

        vm.prank(owner);
        {
            proxy = new TransparentUpgradeableProxy(address(vault), address(owner), "");
            vaultProxy = VaultStETH(payable(proxy));
            vaultProxy.initialize(
                strategy, 
                feeReceiver, 
                marketCapacity, 
                managementFeePercentage, 
                exitFeeRate, 
                deleverageExitFeeRate
            );
        }
    }

    function testConstructor() external {
        assertEq(address(vaultProxy.implementationAddress()), address(vault));
    }

    function testInitialized() external {
        assertEq(address(vaultProxy.strategy()), strategy);
        assertEq(address(vaultProxy.feeReceiver()), feeReceiver);
        assertEq(vaultProxy.marketCapacity(), marketCapacity);
        assertEq(vaultProxy.managementFeePercentage(), managementFeePercentage);
        assertEq(vaultProxy.exitFeeRate(), exitFeeRate);
        assertEq(vaultProxy.deleverageExitFeeRate(), deleverageExitFeeRate);
    }

    function testUpdateStrategy(address _strategy) external {
        if (_strategy == address(0)) {
            vm.expectRevert(bytes("Strategy error!"));
            vaultProxy.updateStrategy(_strategy);
        } else {
            vaultProxy.updateStrategy(_strategy);
            assertEq(address(vaultProxy.strategy()), _strategy);
        }

    }

    function testUpdateFeeReceiver(address _feeReceiver) external {

    }

    function testUpdateMarketCapacity(uint256 _capacity) external {
        if (_capacity <= vaultProxy.marketCapacity()) {
            vm.expectRevert(bytes("Unsupported!"));
            vaultProxy.updateMarketCapacity(_capacity);
        } else {
            vaultProxy.updateMarketCapacity(_capacity);
            assertEq(vaultProxy.marketCapacity(), _capacity);
        }
    }

    function testUpdateManagementFee(uint256 _managementFee) external {
        if (_managementFee > 200) {
            vm.expectRevert(bytes("Management fee exceeds the limit!"));
            vaultProxy.updateManagementFee(_managementFee);
        } else {
            vaultProxy.updateManagementFee(_managementFee);
            assertEq(vaultProxy.managementFeePercentage(), _managementFee);
        }
    }

    function testUpdateExitFeeRate(uint256 _exitFeeRate) external {
        if (_exitFeeRate > 120 || _exitFeeRate == 0) {
            vm.expectRevert(bytes("Exit fee exceeds the limit!"));
            vaultProxy.updateExitFeeRate(_exitFeeRate);
        } else {
            vaultProxy.updateExitFeeRate(_exitFeeRate);
            assertEq(vaultProxy.exitFeeRate(), _exitFeeRate);
        }
    }

    function testUpdateDeleverageExitFeeRate(uint256 _deleverageExitFeeRate) external {
        if (_deleverageExitFeeRate > 120 || _deleverageExitFeeRate == 0) {
            vm.expectRevert(bytes("Deleverage Exit fee exceeds the limit!"));
            vaultProxy.updateDeleverageExitFeeRate(_deleverageExitFeeRate);
        } else {
            vaultProxy.updateDeleverageExitFeeRate(_deleverageExitFeeRate);
            assertEq(vaultProxy.deleverageExitFeeRate(), _deleverageExitFeeRate);
        }
    }
}
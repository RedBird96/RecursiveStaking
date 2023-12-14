// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {TransparentUpgradeableProxy} from "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Test} from "lib/forge-std/src/Test.sol";
import {VaultStETH} from "../src/main/VaultStETH.sol";
import {StrategyDummyImplementation} from "../src/main/StrategyDummyImplementation.sol";
import {StrategyProxy} from "../src/main/StrategyProxy.sol";
import {AdminModule} from "../src/main/strategyModules/AdminModule/AdminModule.sol";
import {UserModule} from "../src/main/strategyModules/AdminModule/UserModule.sol";
import {LeverageModule} from "../src/main/strategyModules/LeverageModule/LeverageModule.sol";
import {MigrateModule} from "../src/main/strategyModules/MigrateModule/MigrateModule.sol";
import {ReadModule} from "../src/main/strategyModules/ReadModule/ReadModule.sol";
import {FlashloanHelper} from "../src/main/flashloanHelper/FlashloanHelper.sol";
import {LendingLogic} from "../src/main/lendingLogic/LendingLogic.sol";
import {DSTest} from "./utils/DSTest.sol";
import {console} from "./utils/console.sol";

contract VaultStETHTest is DSTest {

    VaultStETH public vault;
    VaultStETH public vaultProxy;
    AdminModule public adminProxy;
    UserModule public userProxy;
    LeverageModule public leverageProxy;
    MigrateModule public migrateProxy;
    ReadModule public readProxy;
    StrategyDummyImplementation public dummyImpl;
    StrategyDummyImplementation public dummyImpProxy;
    StrategyProxy public strategyProxy;
    TransparentUpgradeableProxy public proxy;
    FlashloanHelper public flashloanHelper;
    LendingLogic public lendingLogic;
    address public strategy;
    address public feeReceiver;
    address public owner;
    address public rebalancer;
    uint256 public marketCapacity;
    uint256 public managementFeePercentage;
    uint256 public exitFeeRate;
    uint256 public deleverageExitFeeRate;

    function setUp() external {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/7uuQCPu-lHbOrA_pkmzXWvDfx-aj6DxH", 18_763_842);
        
        rebalancer = address(0x576bE7D5F3a6E64bd213c1488595042aa54be6cb);
        owner = address(0x7b08155084680478FF44F26986eb0F598D3D5783);
        strategy = address(0x3fD49A8F37E2349A29EA701b56F10f03B08F1532);
        feeReceiver = address(0xAA172dB9612Da4c71009573e5d1Cf17f8d02B50C);
        marketCapacity = 1000e18;
        managementFeePercentage = 2;
        exitFeeRate = 2;
        deleverageExitFeeRate = 2;
        uint256[] memory safeProtocolRatio = new uint256[](4);
        safeProtocolRatio[0] = 666600000000000000;
        safeProtocolRatio[1] = 857100000000000000;
        safeProtocolRatio[2] = 857100000000000000;
        safeProtocolRatio[3] = 666600000000000000;
        
        address[] memory rebalancers = new address[](1);
        rebalancers[0] = rebalancer;

        vault = new VaultStETH();
        adminProxy = new AdminModule();
        userProxy = new UserModule();
        leverageProxy = new LeverageModule();
        migrateProxy = new MigrateModule();
        readProxy = new ReadModule();
        flashloanHelper = new FlashloanHelper();
        lendingLogic = new LendingLogic();
        dummyImpl = new StrategyDummyImplementation();
        strategyProxy = new StrategyProxy(owner, address(dummyImpl));
        dummyImpProxy = StrategyDummyImplementation(address(proxy));
        bytes4[] memory adminSigArray = new bytes4[](12);
        adminSigArray[0] = 0x9DA7A701; adminSigArray[1] = 0x6817031B;  adminSigArray[2] = 0xdb4cdac3;
        adminSigArray[3] = 0x629099ff; adminSigArray[4] = 0x629099ff;  adminSigArray[5] = 0x629099ff;
        adminSigArray[6] = 0x629099ff; adminSigArray[7] = 0x629099ff;  adminSigArray[8] = 0x629099ff;
        adminSigArray[9] = 0x629099ff; adminSigArray[10] = 0x629099ff; adminSigArray[11] = 0x629099ff;
        bytes4[] memory userSigArray = new bytes4[](2);
        userSigArray[0] = 0xB6B55F25; userSigArray[1] = 0x2E1A7D4D; 
        bytes4[] memory leverageSigArray = new bytes4[](6);
        leverageSigArray[0] = 0xA1555EC9; leverageSigArray[1] = 0x5B3CC4CB; leverageSigArray[2] = 0x68454B7A;
        leverageSigArray[3] = 0xAF8658AB; leverageSigArray[4] = 0x3BFAA7E3; leverageSigArray[5] = 0x335F438B;
        bytes4[] memory migrateSigArray = new bytes4[](2);
        migrateSigArray[0] = 0x38564665; migrateSigArray[1] = 0x04E0A655; 
        bytes4[] memory readSigArray = new bytes4[](28);
        readSigArray[0] = 0x82DFC5F7; readSigArray[1] = 0x2973E0EE;  readSigArray[2] = 0xE107E027;
        readSigArray[3] = 0x8DA5CB5B; readSigArray[4] = 0x98477390;  readSigArray[5] = 0xAFB56385;
        readSigArray[6] = 0xC34C08E5; readSigArray[7] = 0xFBFA77CF;  readSigArray[8] = 0xE549435B;
        readSigArray[9] = 0x1CC3CBEC; readSigArray[10] = 0x9E65741E; readSigArray[11] = 0x98E1862C;
        readSigArray[0] = 0x3E9491A2; readSigArray[1] = 0xE77C41F6;  readSigArray[2] = 0xEA99E689;
        readSigArray[3] = 0x596CEA76; readSigArray[4] = 0x3F221521;  readSigArray[5] = 0x0EF167E4;
        readSigArray[6] = 0x536ECF3D; readSigArray[7] = 0x08AC96D2;  readSigArray[8] = 0x14F70370;
        readSigArray[9] = 0x08BB5FB0; readSigArray[10] = 0x62E8564E; readSigArray[11] = 0x3F6246F5;
        readSigArray[9] = 0xC5BD170B; readSigArray[10] = 0xF5430CAD; readSigArray[11] = 0xCC4A0158;
        readSigArray[11] = 0x0D8E6E2C;
        
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
            strategyProxy.addImplementation(address(adminProxy), adminSigArray);
            // strategyProxy.addImplementation(address(userProxy), userSigArray);
            // strategyProxy.addImplementation(address(leverageProxy), leverageSigArray);
            // strategyProxy.addImplementation(address(migrateProxy), migrateSigArray);
            // strategyProxy.addImplementation(address(readProxy), readSigArray);

            // adminProxy.initialize(
            //     1000,
            //     900000000000000000,
            //     safeProtocolRatio,
            //     rebalancers, 
            //     address(flashloanHelper), 
            //     address(lendingLogic), 
            //     address(feeReceiver)
            // );

            // adminProxy.setVault(address(vaultProxy));
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
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
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
import {BaseDeployer} from "./BaseDeployer.s.sol";
import {console} from "lib/forge-std/src/console.sol";

contract DeployVault is BaseDeployer {

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
    address public feeReceiver;
    address public admin;
    uint256 public marketCapacity;
    uint256 public managementFeePercentage;
    uint256 public exitFeeRate;
    uint256 public deleverageExitFeeRate;

    function setUp() public {
        admin = address(0x2ef73f60F33b167dC018C6B1DCC957F4e4c7e936);
        feeReceiver = address(0xAA172dB9612Da4c71009573e5d1Cf17f8d02B50C);
        marketCapacity = 1000e18;
        managementFeePercentage = 2;
        exitFeeRate = 2;
        deleverageExitFeeRate = 2;
    }

    function vaultDeployLocal() external setEnvDeploy(Cycle.Dev) {
        createSelectFork(Chains.LocalSepolia);
        _chainVault();
    }

    function vaultDeployTestnet() external setEnvDeploy(Cycle.Test) {
        createSelectFork(Chains.Sepolia);
        _chainVault();
    }

    function vaultDeploySelectedChains(
        Chains[] calldata deployForks,
        Cycle cycle
    ) external setEnvDeploy(cycle){
        for (uint256 i; i < deployForks.length; ) {
            
            createSelectFork(deployForks[i]);
            _chainVault();
        
            unchecked {
                ++i;
            }
        }
    }

    function _chainVault() private broadcast(_deployerPrivateKey) {
        vault = new VaultStETH();
        adminProxy = new AdminModule();
        userProxy = new UserModule();
        leverageProxy = new LeverageModule();
        migrateProxy = new MigrateModule();
        readProxy = new ReadModule();
        flashloanHelper = new FlashloanHelper();
        lendingLogic = new LendingLogic();
        dummyImpl = new StrategyDummyImplementation();
        strategyProxy = new StrategyProxy(admin, address(dummyImpl));
        dummyImpProxy = StrategyDummyImplementation(address(strategyProxy));

        proxy = new TransparentUpgradeableProxy(address(vault), tx.origin, "");
        vaultProxy = VaultStETH(payable(proxy));
        vaultProxy.initialize(
            address(dummyImpProxy), 
            feeReceiver, 
            marketCapacity, 
            managementFeePercentage, 
            exitFeeRate, 
            deleverageExitFeeRate
        );

        console.log("============================================");
        console.log("Vault Implementation", address(vault));
        console.log("Vault Proxy", address(vaultProxy));
        console.log("Admin Module", address(adminProxy));
        console.log("User Module", address(userProxy));
        console.log("Leverage Module", address(leverageProxy));
        console.log("Migrate Module", address(migrateProxy));
        console.log("Read Module", address(readProxy));
        console.log("Flashloan Helper", address(flashloanHelper));
        console.log("LendingLogic", address(lendingLogic));
        console.log("Strategy Dummy", address(dummyImpl));
        console.log("Strategy Proxy", address(dummyImpProxy));
        console.log("============================================");
        _setConfiguration();
    }

    function _setConfiguration() private {

        bytes4[] memory adminSigArray = new bytes4[](12);
        adminSigArray[0] = 0x9DA7A701; adminSigArray[1] = 0x6817031B;  adminSigArray[2] = 0xdb4cdac3;
        adminSigArray[3] = 0x629099ff; adminSigArray[4] = 0xC69BEBE4;  adminSigArray[5] = 0x536DAAE5;
        adminSigArray[6] = 0x3A54B841; adminSigArray[7] = 0xCA2E0951;  adminSigArray[8] = 0xBF877EE2;
        adminSigArray[9] = 0x2DA4EDC3; adminSigArray[10] = 0xDF373422; adminSigArray[11] = 0xED14D17E;
        bytes4[] memory userSigArray = new bytes4[](2);
        userSigArray[0] = 0xB6B55F25; userSigArray[1] = 0x2E1A7D4D; 
        bytes4[] memory leverageSigArray = new bytes4[](3);
        leverageSigArray[0] = 0x57900342; leverageSigArray[1] = 0x4f0c343e; leverageSigArray[2] = 0xaf8658ab;
        bytes4[] memory migrateSigArray = new bytes4[](2);
        migrateSigArray[0] = 0x38564665; migrateSigArray[1] = 0x04E0A655; 
        bytes4[] memory readSigArray = new bytes4[](28);
        readSigArray[0] = 0x82DFC5F7; readSigArray[1] = 0x2973E0EE;  readSigArray[2] = 0xE107E027;
        readSigArray[3] = 0x8DA5CB5B; readSigArray[4] = 0x98477390;  readSigArray[5] = 0xAFB56385;
        readSigArray[6] = 0xC34C08E5; readSigArray[7] = 0xFBFA77CF;  readSigArray[8] = 0xE549435B;
        readSigArray[9] = 0x1CC3CBEC; readSigArray[10] = 0x9E65741E; readSigArray[11] = 0x98E1862C;
        readSigArray[12] = 0x3E9491A2; readSigArray[13] = 0xE77C41F6;  readSigArray[14] = 0xEA99E689;
        readSigArray[15] = 0x596CEA76; readSigArray[16] = 0x3F221521;  readSigArray[17] = 0x0EF167E4;
        readSigArray[18] = 0x536ECF3D; readSigArray[19] = 0x08AC96D2;  readSigArray[20] = 0x14F70370;
        readSigArray[21] = 0x08BB5FB0; readSigArray[22] = 0x62E8564E; readSigArray[23] = 0x3F6246F5;
        readSigArray[24] = 0xC5BD170B; readSigArray[25] = 0xF5430CAD; readSigArray[26] = 0xCC4A0158;
        readSigArray[27] = 0x0D8E6E2C;

        uint256[] memory safeProtocolRatio = new uint256[](4);
        safeProtocolRatio[0] = 666600000000000000;
        safeProtocolRatio[1] = 857100000000000000;
        safeProtocolRatio[2] = 857100000000000000;
        safeProtocolRatio[3] = 666600000000000000;

        address[] memory rebalancers = new address[](1);
        rebalancers[0] = tx.origin;
        
        strategyProxy.addImplementation(address(adminProxy), adminSigArray);
        strategyProxy.addImplementation(address(userProxy), userSigArray);
        strategyProxy.addImplementation(address(leverageProxy), leverageSigArray);
        strategyProxy.addImplementation(address(migrateProxy), migrateSigArray);
        strategyProxy.addImplementation(address(readProxy), readSigArray);
        dummyImpProxy.initialize(
            1000,
            900000000000000000,
            safeProtocolRatio,
            rebalancers, 
            address(flashloanHelper), 
            address(lendingLogic), 
            address(feeReceiver)
        );

        dummyImpProxy.setVault(address(vaultProxy));
    }

}

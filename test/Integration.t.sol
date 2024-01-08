// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IERC20} from "@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol";
import {Test} from "lib/forge-std/src/Test.sol";
import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
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
import {ILendingLogic} from "../src/main/lendingLogic/base/ILendingLogic.sol";
import {DSTest} from "./utils/DSTest.sol";
import {console} from "./utils/console.sol";

contract IntegrationTest is Test {

    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant STETH_ADDR = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant WSTETH_ADDR = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

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
    uint256 public marketCapacity;
    uint256 public managementFeePercentage;
    uint256 public exitFeeRate;
    uint256 public deleverageExitFeeRate;

    function setUp() external {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/7uuQCPu-lHbOrA_pkmzXWvDfx-aj6DxH", 17_328_107);//18_942_662
        
        owner = address(0x2ef73f60F33b167dC018C6B1DCC957F4e4c7e936);
        strategy = address(0x3fD49A8F37E2349A29EA701b56F10f03B08F1532);
        feeReceiver = address(0xAA172dB9612Da4c71009573e5d1Cf17f8d02B50C);
        marketCapacity = 1000000000e18;
        managementFeePercentage = 2;
        exitFeeRate = 2;
        deleverageExitFeeRate = 2;
        uint256[] memory safeProtocolRatio = new uint256[](4);
        safeProtocolRatio[0] = 666600000000000000;
        safeProtocolRatio[1] = 857100000000000000;
        safeProtocolRatio[2] = 857100000000000000;
        safeProtocolRatio[3] = 666600000000000000;
        
        address[] memory rebalancers = new address[](1);
        rebalancers[0] = owner;

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
        dummyImpProxy = StrategyDummyImplementation(address(strategyProxy));
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
        
        vm.prank(owner);
        proxy = new TransparentUpgradeableProxy(address(vault), address(owner), "");
        vaultProxy = VaultStETH(payable(proxy));
        // console.log("vaultProxy", address(vault), address(vaultProxy), address(proxy));
        vaultProxy.initialize(
            address(strategyProxy), 
            feeReceiver, 
            marketCapacity, 
            managementFeePercentage, 
            exitFeeRate, 
            deleverageExitFeeRate
        );

        vm.startPrank(owner);
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
        vm.stopPrank();
    }

    function testScenario() external {
        // dummyImpProxy.updateExchangePrice();

        uint256 firstdeposit_Amount = 1000e18;
        uint256 seconddeposit_Amount = 2000e18;
        address firstUser = 0x02eD4a07431Bcc26c5519EbF8473Ee221F26Da8b;
        address secondUser = 0x702a39a9d7D84c6B269efaA024dff4037499bBa9;
        deal(firstUser, 10e18);
        deal(secondUser, 10e18);

        vm.startPrank(firstUser);
        IERC20(STETH_ADDR).approve(address(vaultProxy), firstdeposit_Amount);
        vaultProxy.deposit(firstdeposit_Amount, firstUser);
        IERC20(STETH_ADDR).approve(address(vaultProxy), seconddeposit_Amount);
        vaultProxy.deposit(seconddeposit_Amount, secondUser);
        vm.stopPrank();

        vm.prank(owner);
        uint256 stAmount = 3000e18;
        bytes memory _swapData=hex"12aa3caf0000000000000000000000001136B25047E142Fa3018184793aEc68fBB173cE4000000000000000000000000C02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2000000000000000000000000ae7ab96520de3a18e5e111b5eaab095312d7fe840000000000000000000000001136B25047E142Fa3018184793aEc68fBB173cE4000000000000000000000000D6BbDE9174b1CdAa358d2Cf4D57D1a9F7178FBfF000000000000000000000000000000000000000000000000000537a5d727172f000000000000000000000000000000000000000000000000000530f83613b1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000008200005400003a4060ae7ab96520de3a18e5e111b5eaab095312d7fe84a1903eab00000000000000000000000042f527f50f16a103b6ccab48bccca214500c10210020d6bdbf78ae7ab96520de3a18e5e111b5eaab095312d7fe8480a06c4eca27ae7ab96520de3a18e5e111b5eaab095312d7fe841111111254eeb25477b68fb85ed929f73a960582ea4184f4";
        dummyImpProxy.leverage(uint8(ILendingLogic.PROTOCOL.PROTOCOL_AAVEV3), firstdeposit_Amount + seconddeposit_Amount, stAmount, _swapData);
        dummyImpProxy.updateExchangePrice();
        (uint256 totalAssets, , , ) = dummyImpProxy.getNetAssetsInfo();

        bytes memory _deleverageData = hex"12aa3caf000000000000000000000000e37e799d5077682fa0a244d46e5649f71457bd09000000000000000000000000ae7ab96520de3a18e5e111b5eaab095312d7fe84000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000e37e799d5077682fa0a244d46e5649f71457bd090000000000000000000000003fd49a8f37e2349a29ea701b56f10f03b08f153200000000000000000000000000000000000000000000001bb38cb09b209c000000000000000000000000000000000000000000000000001bb1117e7f9ceb435a000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001730000000000000000000000000000000000000000000001550001270000dd00a007e5c0d20000000000000000000000000000000000000000000000b900006a00005051207f39c581f595b53c5cb19bd0b3f8da6c935e2ca0ae7ab96520de3a18e5e111b5eaab095312d7fe840004ea598cb000000000000000000000000000000000000000000000000000000000000000000020d6bdbf787f39c581f595b53c5cb19bd0b3f8da6c935e2ca000a0fbb7cd060093d199263632a4ef4bb438f1feb99e57b4b5f0bd0000000000000000000005c27f39c581f595b53c5cb19bd0b3f8da6c935e2ca0c02aaa39b223fe8d0a0e5c4f27ead9083c756cc200a0f2fa6b66c02aaa39b223fe8d0a0e5c4f27ead9083c756cc200000000000000000000000000000000000000000000001bb221c154a7f3c2ae0000000000000000000b13a5118a898f80a06c4eca27c02aaa39b223fe8d0a0e5c4f27ead9083c756cc21111111254eeb25477b68fb85ed929f73a96058200000000000000000000000000ea4184f4";
        uint256 withdrawAmount = 100e18;
        dummyImpProxy.deleverage(uint8(ILendingLogic.PROTOCOL.PROTOCOL_AAVEV3), withdrawAmount, stAmount, _deleverageData);
        vaultProxy.withdraw(withdrawAmount, secondUser, owner);

    }

}
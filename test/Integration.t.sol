// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TransparentUpgradeableProxy} from "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
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
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/7uuQCPu-lHbOrA_pkmzXWvDfx-aj6DxH", 18_763_842);
        
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
        readSigArray[12] = 0x3E9491A2; readSigArray[13] = 0xE77C41F6;  readSigArray[14] = 0xEA99E689;
        readSigArray[15] = 0x596CEA76; readSigArray[16] = 0x3F221521;  readSigArray[17] = 0x0EF167E4;
        readSigArray[18] = 0x536ECF3D; readSigArray[19] = 0x08AC96D2;  readSigArray[20] = 0x14F70370;
        readSigArray[21] = 0x08BB5FB0; readSigArray[22] = 0x62E8564E; readSigArray[23] = 0x3F6246F5;
        readSigArray[24] = 0xC5BD170B; readSigArray[25] = 0xF5430CAD; readSigArray[26] = 0xCC4A0158;
        readSigArray[27] = 0x0D8E6E2C;
        
        vm.prank(owner);
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
        vm.startPrank(owner);
        dummyImpProxy.updateExchangePrice();

        //user deposit stETH to vault
        uint256 firstdeposit_Amount = 1000e18;
        address firstUser = vm.addr(1);
        deal(STETH_ADDR, firstUser, 9000e18);
        IERC20(STETH_ADDR).approve(address(vaultProxy), firstdeposit_Amount);
        vaultProxy.deposit(firstdeposit_Amount, firstUser);
        uint256 expectedBalance = 8000e18;
        assertEq(IERC20(STETH_ADDR).balanceOf(firstUser), expectedBalance);
        assertEq(vaultProxy.balance(), 0);
        //second user deposit stETH to vault
        uint256 seconddeposit_Amount = 500e18;
        address secondUser = vm.addr(2);
        deal(STETH_ADDR, secondUser, 9000e18);
        IERC20(STETH_ADDR).approve(address(vaultProxy), seconddeposit_Amount);
        vaultProxy.deposit(seconddeposit_Amount, secondUser);
        expectedBalance = 8500e18;
        assertEq(IERC20(STETH_ADDR).balanceOf(secondUser), expectedBalance);
        assertEq(vaultProxy.balance(), 0);

        bytes memory swapData = "0x12aa3caf00000000000000000000000092f3f71cef740ed5784874b8c70ff87ecdf33588000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000ae7ab96520de3a18e5e111b5eaab095312d7fe8400000000000000000000000092f3f71cef740ed5784874b8c70ff87ecdf335880000000000000000000000003fd49a8f37e2349a29ea701b56f10f03b08f153200000000000000000000000000000000000000000000000f87fa41d844ee61b600000000000000000000000000000000000000000000000f744da99190c168d7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002430000000000000000000000000000000000000002250001f70001ad00019300a0c9e75c48000000000000000006040000000000000000000000000000000000000000000000000001650000c900a007e5c0d20000000000000000000000000000000000000000000000a500006900001a4041c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2d0e30db002a0000000000000000000000000000000000000000000000005732515547e93d5f8ee63c1e500109830a1aaad605bbf02a9dfa7b0b92ec2fb7daac02aaa39b223fe8d0a0e5c4f27ead9083c756cc241207f39c581f595b53c5cb19bd0b3f8da6c935e2ca00004de0e9a3e0000000000000000000000000000000000000000000000000000000000000000416021e27a5e5513d6e65c4f830167390997aa84843a00443df0212400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000939d4705db07b1ab80020d6bdbf78ae7ab96520de3a18e5e111b5eaab095312d7fe8400a0f2fa6b66ae7ab96520de3a18e5e111b5eaab095312d7fe8400000000000000000000000000000000000000000000000f882f2da3054306500000000000000000000ab00d1d7e6a2880a06c4eca27ae7ab96520de3a18e5e111b5eaab095312d7fe841111111254eeb25477b68fb85ed929f73a9605820000000000000000000000000000000000000000000000000000000000ea4184f4";

        //protocolId = 0, flashloanSelector = 0
        dummyImpProxy.leverage(
            0, 
            0, 
            1000e18, 
            swapData, 
            980e18, 
            0
        );

        assertEq(vaultProxy.balance(), firstdeposit_Amount + seconddeposit_Amount);
        uint256 deleverageWithdrawFee = vaultProxy.
            getDeleverageWithdrawFee(firstdeposit_Amount);
        uint256 deleverageWithdrawAmount = vaultProxy.
            getDeleverageWithdrawAmount(seconddeposit_Amount, false, 0);
        uint256 totalAssets = vaultProxy.totalAssets();
        uint256 price = dummyImpProxy.exchangePrice();
        assertEq(totalAssets, price);
        dummyImpProxy.updateExchangePrice();

        //protocolId = 0, flashloanSelector = 1
        dummyImpProxy.leverage(
            0, 
            0,  
            1000e18, 
            swapData, 
            980e18, 
            1
        );
        
        totalAssets = vaultProxy.totalAssets();

        dummyImpProxy.updateExchangePrice();

        uint256 firstDeleverageAmount = 200e18;
        dummyImpProxy.deleverage(
            0, 
            firstDeleverageAmount, 
            1000e18, 
            swapData, 
            980e18, 
            1
        );
        totalAssets = vaultProxy.totalAssets();
        dummyImpProxy.updateExchangePrice();
        price = dummyImpProxy.exchangePrice();

        assertEq(price, 0);

        //protocolId = 1, flashloanSelector = 0
        dummyImpProxy.leverage(
            1, 
            0, 
            1000e18, 
            swapData, 
            980e18, 
            0
        );
        totalAssets = vaultProxy.totalAssets();
        dummyImpProxy.updateExchangePrice();
        price = dummyImpProxy.exchangePrice();

        //protocolId = 1, flashloanSelector = 1
        dummyImpProxy.leverage(
            1, 
            0, 
            1000e18, 
            swapData, 
            980e18, 
            1
        );
        dummyImpProxy.updateExchangePrice();

        dummyImpProxy.deleverageAndWithdraw(
            1, 
            0, 
            swapData, 
            980e18, 
            false, 
            1
        );

        vm.stopPrank();
    }

}
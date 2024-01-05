// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol";
import {AdminModule} from "../src/main/strategyModules/AdminModule/AdminModule.sol";
import {StrategyDummyImplementation} from "../src/main/StrategyDummyImplementation.sol";
import {StrategyProxy} from "../src/main/StrategyProxy.sol";
import {DSTest} from "./utils/DSTest.sol";
import {console} from "./utils/console.sol";

contract AdminModuleTest is DSTest {

    AdminModule public adminModule;
    StrategyDummyImplementation public dummyImpl;
    StrategyDummyImplementation public dummyImpProxy;
    StrategyProxy public proxy;
    address public vault;
    address public admin;
    address public feeReceiver;

    function setUp() external {

        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/7uuQCPu-lHbOrA_pkmzXWvDfx-aj6DxH", 18_763_842);

        vault = address(0xcDd374F491fBF3f4FcF6E9023c99043774005137);
        admin = address(0x7b08155084680478FF44F26986eb0F598D3D5783);
        feeReceiver = address(0xAA172dB9612Da4c71009573e5d1Cf17f8d02B50C);
        adminModule = new AdminModule();
        dummyImpl = new StrategyDummyImplementation();
        proxy = new StrategyProxy(admin, address(dummyImpl));
        dummyImpProxy = StrategyDummyImplementation(address(proxy));
        bytes4[] memory sigArray = new bytes4[](4);
        sigArray[0] = 0x9DA7A701;
        sigArray[1] = 0x6817031B;
        sigArray[2] = 0xdb4cdac3;
        sigArray[3] = 0x629099ff;
        vm.prank(admin);
        proxy.addImplementation(address(adminModule), sigArray);
    }

    // function testSetVault(address _vault) public {
    //     // dummyImpProxy.setVault(_vault);
    //     // assertEq(address(dummyImpProxy.vault()), _vault);
    // }

    // function testUpdateFeeReceiver() public {
    //     // dummyImpProxy.updateFeeReceiver(feeReceiver);
    //     // asseretEq(uint256(dummyImpProxy.revenue()), 0);
    // }

    // function testUpdateSafeProtocolRatio(
    //     uint8[] calldata _protocolId, 
    //     uint256[] calldata _safeProtocolRatio
    // ) public {
    //     // dummyImpProxy.updateSafeProtocolRatio(_protocolId, _safeProtocolRatio);
    //     // assertEq(, b);
    // }

}
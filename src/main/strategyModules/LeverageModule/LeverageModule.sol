// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/contracts/interfaces/IERC3156FlashBorrower.sol";
import {IERC20} from "@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol";
import {IAaveOracle} from "../../../interfaces/aave/IAaveOracle.sol";
import {IFlashloanHelper} from "../../flashloanHelper/IFlashloanHelper.sol";
import {IFlashloaner} from "../../strategyBase/IFlashloaner.sol";
import {ILendingLogic} from "../../lendingLogic/base/ILendingLogic.sol";
import {FlashloanHelper} from "../../flashloanHelper/FlashloanHelper.sol";
import {IAggregationRouterV5} from "../../../interfaces/1inch/IAggregationRouterV5.sol";
import {IWETH} from "../../../interfaces/weth/IWETH.sol";
import {Basic} from "../../strategyBase/basic.sol";
import {OneinchCaller} from "../../1inch/OneinchCaller.sol";
import {console} from "lib/forge-std/src/console.sol";

contract LeverageModule is Basic, OneinchCaller{

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    IAaveOracle public constant aaveOracleV3 = IAaveOracle(0x54586bE62E3c3580375aE3723C145253060Ca0C2);

    enum MODULE {
        LEVERAGE_MODE,
        DELEVERAGE_MODE
    }

    /**
    * @dev adjust position leverage according the flashloan
    * @param _protocolId Protocol Index
    * @param _stETHDepositAmount stETH amount for deposit
    * @param _wEthDebtAmount wETH amount for debt on flashloan
    * @param _swapData swap bytes data 
    */
    function leverage(
        uint8 _protocolId,
        uint256 _stETHDepositAmount,
        uint256 _wEthDebtAmount,
        bytes calldata _swapData
    ) external onlyOwner {

        uint256 balance = IERC20(STETH_ADDR).balanceOf(address(this));
        require(balance >= 0, "Insufficient stETH balance");

        bytes memory dataBytes = abi.encode(
            uint256(IFlashloaner.MODULE.MODULE_ONE), 
            uint256(IFlashloanHelper.PROVIDER.PROVIDER_AAVEV3),
            _protocolId,
            uint8(MODULE.LEVERAGE_MODE),
            _stETHDepositAmount,
            _swapData
        );
        
        IFlashloanHelper(flashloanHelper).flashLoan(
            IERC3156FlashBorrower(
                address(this)), 
                WETH_ADDR, 
                _wEthDebtAmount, 
                dataBytes
        );

    }

    /**
    * @dev adjust position deleverage according the flashloan
    * @param _protocolId Protocol Index
    * @param _stETHWithdrawAmount stETH token withdraw amount
    * @param _wEthDebtDeleverageAmount wETH amount for debt on flashloan
    * @param _swapData swap bytes data 
    */
    function deleverage(
        uint8 _protocolId,
        uint256 _stETHWithdrawAmount,
        uint256 _wEthDebtDeleverageAmount,
        bytes calldata _swapData
    ) external onlyOwner  {

        uint256 maxWithdrawsStETH = getAvailableWithdrawsStETH(_protocolId);
        require(maxWithdrawsStETH < _stETHWithdrawAmount, "Not enough token balance");

        bytes memory dataBytes = abi.encode(
            uint256(IFlashloaner.MODULE.MODULE_ONE), 
            uint256(IFlashloanHelper.PROVIDER.PROVIDER_AAVEV3),
            _protocolId,
            uint8(MODULE.DELEVERAGE_MODE),
            _stETHWithdrawAmount,
            _swapData
        );
        
        IFlashloanHelper(flashloanHelper).flashLoan(
            IERC3156FlashBorrower(
                address(this)), 
                WETH_ADDR, 
                _wEthDebtDeleverageAmount, 
                dataBytes
        );
    }

    /**
    * @dev 
    */
    function onFlashLoanOne(
        address _initiator, //0x3fD49A8F37E2349A29EA701b56F10f03B08F1532
        address _token, //0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
        uint256 _amount, //1468560302348079
        uint256 _fee, //
        bytes calldata _params
    ) external returns (bytes32) {
        
        require(_initiator == address(this), "Cannot call FlashLoan module");

        (uint8 _protocolId, uint8 _module, uint256 _operatorAmount, bytes memory _swapData) = 
            abi.decode(_params, (uint8, uint8, uint256, bytes));

        if (_module == uint8(MODULE.LEVERAGE_MODE)) {

            (uint256 returnAmount_, ) =
                executeSwap(_amount, WETH_ADDR, STETH_ADDR, _swapData, 0);

            executeDeposit(_protocolId, STETH_ADDR, returnAmount_ + _operatorAmount);
            uint256 borrowAmount = getAvailableBorrowsETH(_protocolId);
            executeBorrow(_protocolId, _token, borrowAmount);
        } else {
            
            uint256 wEthPrice_ = aaveOracleV3.getAssetPrice(WETH_ADDR);
            uint256 stEthPrice_ = aaveOracleV3.getAssetPrice(STETH_ADDR);

            uint256 wethWithdrawAmount = _operatorAmount * stEthPrice_ / wEthPrice_;
            executeRepay(_protocolId, _token, wethWithdrawAmount + _fee);

            executeWithdraw(_protocolId, STETH_ADDR, _operatorAmount);

            executeSwap(_amount, STETH_ADDR, WETH_ADDR, _swapData, 0);

        }

        IERC20(_token).approve(msg.sender, _amount + _fee);
        return CALLBACK_SUCCESS;
    }
}
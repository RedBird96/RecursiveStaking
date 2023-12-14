// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC3156FlashBorrower} from "lib/openzeppelin-contracts/contracts/interfaces/IERC3156FlashBorrower.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IFlashloanHelper} from "../../flashloanHelper/IFlashloanHelper.sol";
import {IFlashloaner} from "../../strategyBase/IFlashloaner.sol";
import {ILendingLogic} from "../../lendingLogic/base/ILendingLogic.sol";
import {FlashloanHelper} from "../../flashloanHelper/FlashloanHelper.sol";
import {IAggregationRouterV5} from "../../../interfaces/1inch/IAggregationRouterV5.sol";
import {IWETH} from "../../../interfaces/weth/IWETH.sol";
import {Basic} from "../../strategyBase/basic.sol";
import {OneinchCaller} from "../../1inch/OneinchCaller.sol";

contract LeverageModule is Basic, OneinchCaller{

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /**
    * @dev adjust position leverage according the flashloan
    * @param _protocolId The index number of the lending protocol.
    * @param _deposit The amount of deposit for lending
    * @param _debtAmount debt Amount for flashloan
    * @param _swapData swap bytes data 
    * @param _swapGetMin swap minimum amount
    * @param _flashloanSelector flashloan selector
    */
    function leverage(
        uint8 _protocolId,
        uint256 _deposit,
        uint256 _debtAmount,
        bytes calldata _swapData,
        uint256 _swapGetMin,
        uint256 _flashloanSelector
    ) external {

        executeDeposit(_protocolId, STETH_ADDR, _deposit);
        (uint256 ratio, bool _isOkay) = getProtocolCollateralRatio(_protocolId);
        require(ratio > 80, "collateralization ratio is bigger than 80%");
        uint256 availableBorrowsETH = getAvailableBorrowsETH(_protocolId);
        require(availableBorrowsETH < _debtAmount, "Debt Amount is too big");

        bytes memory dataBytes = abi.encode(
            uint256(IFlashloaner.MODULE.MODULE_ONE), 
            uint256(IFlashloanHelper.PROVIDER(_flashloanSelector)), 
            _swapData
        );
        
        require(
            IFlashloanHelper(flashloanHelper).flashLoan(address(this), WETH_ADDR, _debtAmount, dataBytes),
            "flashloan failed"
        );

        (ratio, _isOkay) = getProtocolCollateralRatio(_protocolId);
        (uint256 _totalAssets, uint256 _totalDebt, uint256 _netAssets, uint256 _aggregatedRatio) = getNetAssetsInfo();

        uint256 balance = IERC20(STETH_ADDR).balanceOf(address(this));
    }

    function deleverage(
        uint8 _protocolId,
        uint256 _withdraw,
        uint256 _debtAmount,
        bytes calldata _swapData,
        uint256 _swapGetMin,
        uint256 _flashloanSelector
    ) external {

        if (_flashloanSelector == 1) {
            uint256 maxWithdrawsStETH = getAvailableWithdrawsStETH(_protocolId);
            require(maxWithdrawsStETH < _withdraw, "Not enough balance");

            executeWithdraw(_protocolId, WSTETH_ADDR, _withdraw);

            bytes memory dataBytes = abi.encode(
                uint256(IFlashloaner.MODULE.MODULE_ONE), 
                uint256(IFlashloanHelper.PROVIDER(_flashloanSelector)), 
                _swapData
            );
            require(
                IFlashloanHelper(flashloanHelper).flashLoan(address(this), WETH_ADDR, _debtAmount, dataBytes),
                "flashloan failed"
            );

            (uint256 ratio, bool _isOkay) = getProtocolCollateralRatio(_protocolId);
            (uint256 totalAssets, uint256 totalDebt, uint256 netAssets, uint256 aggregatedRatio) = 
                getNetAssetsInfo();
                
            uint256 balance = IERC20(STETH_ADDR).balanceOf(address(this));
        } else {
            
            ILendingLogic(lendingLogic).withdraw(_protocolId, WSTETH_ADDR, _withdraw);
        }

    }

    // function deleverageAndWithdraw(
    //     uint8 _protocolId,
    //     uint256 _withdrawShare,
    //     bytes calldata _swapData,
    //     uint256 _swapGetMin,
    //     bool _isETH,
    //     uint256 _flashloanSelector
    // ) external returns (uint256) {
    //     uint256 amount = getDeleverageAmount(_withdrawShare, _protocolId);
    // }

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
        
        (uint256 flag, uint256 swapGetMin, uint8 _protocolId, bytes memory swapBytes) = 
            abi.decode(_params, (uint256, uint256, uint8, bytes));

        if (flag == 0) {
            IWETH(WETH_ADDR).withdraw(_amount);
            
            (uint256 returnAmount_, uint256 inputAmount_) =
                executeSwap(_amount, ETH_ADDR, STETH_ADDR, swapBytes, swapGetMin);

            executeDeposit(_protocolId, STETH_ADDR, _amount);
            executeBorrow(_protocolId, WETH_ADDR, _amount);
        } else {
            executeRepay(_protocolId, WETH_ADDR, _amount);
            executeWithdraw(_protocolId, WSTETH_ADDR, _amount);
            (uint256 returnAmount_, uint256 inputAmount_) =
                executeSwap(_amount, STETH_ADDR, WETH_ADDR, swapBytes, swapGetMin);
            executeBorrow(_protocolId, WETH_ADDR, _amount);
        }

        return CALLBACK_SUCCESS;
    }

    // function getDeleverageAmount(
    //     uint256 _share, 
    //     uint8 _protocolId
    // ) public view returns (uint256) {
        
    // }
}
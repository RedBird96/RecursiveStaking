// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC3156FlashBorrower} from "lib/openzeppelin-contracts/contracts/interfaces/IERC3156FlashBorrower.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Basic} from "../../strategyBase/basic.sol";
import {IFlashloanHelper} from "../../flashloanHelper/IFlashloanHelper.sol";
import {IFlashloaner} from "../../strategyBase/IFlashloaner.sol";
import {ILendingLogic} from "../../lendingLogic/base/ILendingLogic.sol";
import {FlashloanHelper} from "../../flashloanHelper/FlashloanHelper.sol";
import {IAggregationRouterV5} from "../../../interfaces/1inch/IAggregationRouterV5.sol";

contract LeverageModule is Basic {

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

        if (_protocolId == 0) {
            if (_flashloanSelector == 0) {
                // IERC20(STETH_ADDR).transfer(feeReceiver, amount);
                
            } else {
                ILendingLogic(lendingLogic).deposit(_protocolId, STETH_ADDR, _deposit);
                uint256 ratio = ILendingLogic(lendingLogic).getProtocolCollateralRatio(_protocolId, address(this));
                require(ratio > 80, "collateralization ratio is bigger than 80%");
                uint256 availableBorrowsETH = ILendingLogic(lendingLogic).getAvailableBorrowsETH(_protocolId, address(this));
                require(availableBorrowsETH < _debtAmount, "Debt Amount is too big");

                bytes memory dataBytes = abi.encode(uint256(IFlashloaner.MODULE.MODULE_ONE), uint256(IFlashloanHelper.PROVIDER.PROVIDER_AAVEV3), _swapData);
                require(
                    IFlashloanHelper(flashloanHelper).flashLoan(address(this), WETH_ADDR, _debtAmount, dataBytes)
                        == CALLBACK_SUCCESS,
                    "flashloan failed"
                );

                ratio = ILendingLogic(lendingLogic).getProtocolCollateralRatio(_protocolId, address(this));
                (uint256, uint256, uint256, uint256) = ILendingLogic(lendingLogic).getNetAssetsInfo(address(this));
                uint256 balance = IERC20(STETH_ADDR).balanceOf(address(this));
            }
        } else {
            if (_flashloanSelector == 0) {

            } else {

            }
        }

    }

    function deleverage(
        uint8 _protocolId,
        uint256 _withdraw,
        uint256 _debtAmount,
        bytes calldata _swapData,
        uint256 _swapGetMin,
        uint256 _flashloanSelector
    ) external {

    }

    function deleverageAndWithdraw(
        uint8 _protocolId,
        uint256 _withdrawShare,
        bytes calldata _swapData,
        uint256 _swapGetMin,
        bool _isETH,
        uint256 _flashloanSelector
    ) external returns (uint256) {

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



        // ILendingLogic(lendingLogic).deposit(_protocolId, STETH_ADDR, _amount);
        // ILendingLogic(lendingLogic).borrow(_protocolId, _token, amount);

        // (uint8 _protocolId, uint256 _stAmount, uint256 _debtAmount) = 
        // abi.decode(_params, (uint8, uint256, uint256));
        // executeDeposit(_protocolId, STETH_ADDR, _stAmount);


        // bytes memory dataBytes = abi.encode(uint256(IFlashloaner.MODULE.MODULE_TWO), uint256(IFlashloanHelper.PROVIDER.PROVIDER_BALANCER), _params);
        // IFlashloanHelper(flashloanHelper).flashLoan(address(this), _token, _amount, dataBytes);

        return CALLBACK_SUCCESS;
    }

    function getDeleverageAmount(
        uint256 _share, 
        uint8 _protocolId
    ) public view returns (uint256) {
        
    }
}
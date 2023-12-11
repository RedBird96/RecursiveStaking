// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {Basic} from "../../strategyBase/basic.sol";
import {IFlashloanHelper} from "../../flashloanHelper/IFlashloanHelper.sol";
import {ILendingLogic} from "../../lendingLogic/base/ILendingLogic.sol";

contract LeverageModule is Basic {

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
        // bytes memory dataBytes = abi.encode(uint256(0), uint256(IFlashloanHelper.PROVIDER.PROVIDER_AAVEV3), _swapData);
        // IFlashloanHelper(flashloanHelper).flashLoan(address(this), _token, _amount, dataBytes);
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
        address _initiator, 
        address _token, 
        uint256 _amount, 
        uint256 _fee, 
        bytes calldata _params
    ) external returns (bytes32) {

    }

    function getDeleverageAmount(
        uint256 _share, 
        uint8 _protocolId
    ) public view returns (uint256) {

    }
}
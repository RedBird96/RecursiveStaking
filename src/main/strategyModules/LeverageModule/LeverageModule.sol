// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {Basic} from "../../strategyBase/basic.sol";

contract LeverageModule is Basic {

    function leverage(
        uint8 _protocolId,
        uint256 _deposit,
        uint256 _debtAmount,
        bytes calldata _swapData,
        uint256 _swapGetMin,
        uint256 _flashloanSelector
    ) external {


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

    function getDeleverageAmount(
        uint256 _share, 
        uint8 _protocolId
    ) public view returns (uint256) {

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

    function onFlashLoanOne(
        address _initiator, 
        address _token, 
        uint256 _amount, 
        uint256 _fee, 
        bytes calldata _params
    ) external returns (bytes32) {

    }


}
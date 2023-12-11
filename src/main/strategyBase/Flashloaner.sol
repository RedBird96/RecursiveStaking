// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;


contract Flashloaner {

    function onFlashLoanOne(
        address _initiator, 
        address _token, 
        uint256 _amount, 
        uint256 _fee, 
        bytes calldata _params
    ) external returns (bytes32) {
     //   return onFlashLoanOne(_initiator, _token, _amount, _fee, _params);
    }

    function onFlashLoanTwo(
        address _initiator, 
        address _token, 
        uint256 _amount, 
        uint256 _fee, 
        bytes calldata _params
    ) external returns (bytes32) {

    //    return onFlashLoanTwo(_initiator, _token, _amount, _fee, _params);

    }
}
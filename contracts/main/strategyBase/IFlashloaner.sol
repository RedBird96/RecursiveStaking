// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IFlashloaner {
    enum MODULE {
        MODULE_ONE, // For LeverageModule
        MODULE_TWO // For MigrateModule
    }

    function onFlashLoanOne(address _initiator, address _token, uint256 _amount, uint256 _fee, bytes calldata _params)
        external
        returns (bytes32);

    function onFlashLoanTwo(address _initiator, address _token, uint256 _amount, uint256 _fee, bytes calldata _params)
        external
        returns (bytes32);
}
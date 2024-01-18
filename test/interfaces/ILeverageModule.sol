// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ILeverageModule {
    function leverage(
        uint8 _protocolId,
        uint256 _deposit,
        uint256 _debtAmount,
        bytes calldata _swapData,
        uint256 _swapGetMin
    ) external;

    function deleverage(
        uint8 _protocolId,
        uint256 _withdraw,
        uint256 _debtAmount,
        bytes calldata _swapData,
        uint256 _swapGetMin
    ) external;

    function deleverageAndWithdraw(
        uint8 _protocolId,
        uint256 _withdrawShare,
        bytes calldata _swapData,
        uint256 _swapGetMin
    ) external returns (uint256);

    function onFlashLoanOne(address _initiator, address _token, uint256 _amount, uint256 _fee, bytes calldata _params)
        external
        returns (bytes32);

    function updateExchangePrice() external returns (uint256 newExchangePrice_, uint256 newRevenue_);
}
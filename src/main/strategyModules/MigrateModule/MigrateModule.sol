// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH} from "../../../interfaces/weth/IWETH.sol";
import {Basic} from "../../strategyBase/basic.sol";
import {FlashloanHelper} from "../../flashloanHelper/FlashloanHelper.sol";

contract MigrateModule is Basic {

    using SafeERC20 for IERC20;
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    address public constant balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    function onFlashLoanTwo(
        address _initiator, 
        address _token, 
        uint256 _amount, 
        uint256 _fee, 
        bytes calldata _params
    ) external returns (bytes32) {

        IWETH(WETH_ADDR).withdraw(_amount);
        (uint256 swapGetMin, uint8 _protocolId, bytes memory swapBytes) = 
            abi.decode(_params, (uint256, uint8, bytes));

        executeDeposit(_protocolId, STETH_ADDR, _amount);
        executeBorrow(_protocolId, WETH_ADDR, _amount);

        return CALLBACK_SUCCESS;
    }

    function receiveFlashLoan(
        IERC20[] memory _loanTokens,
        uint256[] memory _loanAmounts,
        uint256[] memory,
        bytes memory _callbackData
    ) external {
        require(msg.sender == balancerVault && executor != address(0), "Invalid call!");
        (uint8 fromProtocolId_, uint8 toProtocolId_, uint256 stAmount_, uint256 _debtAmount) = 
        abi.decode(_callbackData, (uint8, uint8, uint256, uint256));
        executeRepay(fromProtocolId_, WETH_ADDR, _debtAmount);
        executeWithdraw(fromProtocolId_, STETH_ADDR, stAmount_);
        executeDeposit(toProtocolId_, STETH_ADDR, stAmount_);
        executeBorrow(toProtocolId_, WETH_ADDR, _debtAmount);
        _loanTokens[0].safeTransfer(balancerVault, _loanAmounts[0]);
        executor = address(0);
    }
}
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Events} from "./events.sol";

/**
 * @title UserModule contract
 * @dev This module controls the flow of funds between the strategy contract 
 * and the vault contract when users deposit or withdraw funds.
 */
contract UserModule is Events {
    using SafeERC20 for IERC20;

    /**
     * @dev The asset deposit operation is called by the Vault contract on behalf of the user.
     * @param _amount The amount of stETH deposited by the user.
     * @param operateExchangePrice The exchange rate used during the deposit operation.
     */
    function deposit(uint256 _amount) external onlyVault returns (uint256 operateExchangePrice) {
        require(_amount > 0, "deposit: Invalid amount.");
        operateExchangePrice = exchangePrice;
        IERC20(STETH_ADDR).safeTransferFrom(vault, address(this), _amount);

        emit Deposit(_amount);
    }

    /**
     * @dev The asset withdraw operation is called by the Vault contract on behalf of the user.
     * @param _amount The amount of stETH the user wants to withdraw.
     * @param withdrawAmount The actual amount of stETH withdrawn by the user.
     */
    function withdraw(uint256 _amount) external onlyVault returns (uint256 withdrawAmount) {
        require(_amount > 0, "withdraw: Invalid amount.");
        IERC20(STETH_ADDR).safeTransfer(vault, _amount);
        withdrawAmount = _amount;

        emit Withdraw(_amount);
    }

    function getAvailableLogicBalance() external onlyOwner returns(uint256 balance) {
        balance = IERC20(STETH_ADDR).balanceOf(address(this));
    }
}
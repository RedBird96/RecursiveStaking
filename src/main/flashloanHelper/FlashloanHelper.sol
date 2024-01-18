// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC3156FlashLender} from "@openzeppelin/contracts/contracts/interfaces/IERC3156FlashLender.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/contracts/interfaces/IERC3156FlashBorrower.sol";
import {IFlashLoanSimpleReceiver} from "../../interfaces/aave/v3/IFlashLoanSimpleReceiver.sol";
import {IFlashLoanRecipient} from "../../interfaces/balancer/IFlashLoanRecipient.sol";
import {IPoolV3} from "../../interfaces/aave/v3/IPoolV3.sol";
import {IVault} from "../../interfaces/balancer/IVault.sol";
import {IFlashloaner} from "../strategyBase/IFlashloaner.sol";
import {IFlashloanHelper} from "./IFlashloanHelper.sol";
import {console} from "lib/forge-std/src/console.sol";

/**
 * @title FlashloanHelper contract
 * @notice This contract acts as an aggregator for flash loan providers.
 * @dev Use different protocols for flash loans by using different IDs,
 * while eliminating the ABI differences between different protocols.
 */
contract FlashloanHelper is IFlashloanHelper, IFlashLoanSimpleReceiver, IFlashLoanRecipient {
    using SafeERC20 for IERC20;

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    address public constant aaveV3Pool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public constant balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    // Prevent re-entry calls by using this flag.
    address public executor;

    /**
     * @dev The entry function for executing the flash loan operation.
     * @param _receiver The contract of the callback function receiving the flash loan operation.
     * @param _token The type of token required for the flash loan.
     * @param _amount The amount of token required for the flash loan.
     * @param _dataBytes The parameters for executing the callback.
     * @return bool The flag indicating the operation has been completed.
     */
    function flashLoan(IERC3156FlashBorrower _receiver, address _token, uint256 _amount, bytes calldata _dataBytes)
        external
        override
        returns (bool)
    {
        require(executor == address(0) && address(_receiver) == msg.sender, "FlashloanHelper: In progress!");
        executor = msg.sender;
        (, uint256 flashloanSelector_,,,,, ) = 
            abi.decode(_dataBytes, (uint256, uint256, uint8, uint8, uint256, uint256, bytes));

        if (flashloanSelector_ == uint256(IFlashloanHelper.PROVIDER.PROVIDER_AAVEV3)) {
            IPoolV3(aaveV3Pool).flashLoanSimple(address(this), _token, _amount, _dataBytes, 0);
        } else if (flashloanSelector_ == uint256(IFlashloanHelper.PROVIDER.PROVIDER_BALANCER)) {
            IERC20[] memory tokens_ = new IERC20[](1);
            uint256[] memory amounts_ = new uint256[](1);
            tokens_[0] = IERC20(_token);
            amounts_[0] = _amount;
            IVault(balancerVault).flashLoan(this, tokens_, amounts_, _dataBytes);
        } else {
            revert("FlashloanSelector error.");
        }
        executor = address(0);

        return true;
    }

    /**
     * @notice Executes an operation after receiving the flash-borrowed asset.
     * @dev AaveV3 flashloan callback.
     * @dev Ensure that the contract can return the debt + premium, e.g., has
     * enough funds to repay and has approved the pool to pull the total amount.
     * @param _asset The address of the flash-borrowed asset.
     * @param _amount The amount of the flash-borrowed asset.
     * @param _premium The fee of the flash-borrowed asset.
     * @param _initiator The address of the flashloan initiator.
     * @param _params The byte-encoded params passed when initiating the flashloan.
     * @return True if the execution of the operation succeeds, false otherwise.
     */
    function executeOperation(
        address _asset,
        uint256 _amount,
        uint256 _premium,
        address _initiator,
        bytes calldata _params
    ) external override returns (bool) {

        require(msg.sender == aaveV3Pool && _initiator == address(this), "Aave flashloan: Invalid call!");
        IERC20(_asset).safeTransfer(executor, _amount);
        (uint256 module_,,uint8 protocolId_,uint8 leverageModule_, uint256 operateAmount_, uint256 minimumAmount_, bytes memory callBackData_) = 
            abi.decode(_params, (uint256, uint256, uint8, uint8, uint256, uint256, bytes));

        bytes memory passBytes = abi.encode(
            protocolId_,
            leverageModule_,
            operateAmount_,
            minimumAmount_,
            callBackData_
        );
        /// @dev There will be two modules in the strategy that need to use the flash loan operation,
        /// which are distinguished by two callback functions.
        if (module_ == uint256(IFlashloaner.MODULE.MODULE_ONE)) {
            require(
                IFlashloaner(executor).onFlashLoanOne(executor, _asset, _amount, _premium, passBytes)
                    == CALLBACK_SUCCESS,
                "Aave flashloan for module one failed"
            );
        } else if (module_ == uint256(IFlashloaner.MODULE.MODULE_TWO)) {
            require(
                IFlashloaner(executor).onFlashLoanTwo(executor, _asset, _amount, _premium, callBackData_)
                    == CALLBACK_SUCCESS,
                "Aave flashloan for module two failed"
            );
        } else {
            revert("Nonexistent Module!");
        }
        IERC20(_asset).safeTransferFrom(executor, address(this), _amount + _premium);
        IERC20(_asset).safeIncreaseAllowance(aaveV3Pool, _amount + _premium);
        return true;
    }

    /**
     * @notice Executes an operation after receiving the flash-borrowed asset.
     * @dev Balancer flashloan callback.
     * @dev Ensure that the contract can return the debt + fee, e.g., has
     * enough funds to repay and has approved the Pool to pull the total amount.
     * @param _tokens The addresses of the flash-borrowed asset.
     * @param _amounts The amounts of the flash-borrowed asset.
     * @param _fees The fees of the flash-borrowed asset.
     * @param _params The byte-encoded params passed when initiating the flashloan.
     */
    function receiveFlashLoan(
        IERC20[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256[] calldata _fees,
        bytes calldata _params
    ) external override {
        require(msg.sender == balancerVault && executor != address(0), "Balancer flashloan: Invalid call!");
        _tokens[0].safeTransfer(executor, _amounts[0]);
        (uint256 module_,, bytes memory callBackData_) = abi.decode(_params, (uint256, uint256, bytes));
        /// @dev There will be two modules in the strategy that need to use the flash loan operation,
        /// which are distinguished by two callback functions.
        if (module_ == uint256(IFlashloaner.MODULE.MODULE_ONE)) {
            require(
                IFlashloaner(executor).onFlashLoanOne(
                    executor, address(_tokens[0]), _amounts[0], _fees[0], callBackData_
                ) == CALLBACK_SUCCESS,
                "Balancer flashloan for module one failed"
            );
        } else if (module_ == uint256(IFlashloaner.MODULE.MODULE_TWO)) {
            require(
                IFlashloaner(executor).onFlashLoanTwo(
                    executor, address(_tokens[0]), _amounts[0], _fees[0], callBackData_
                ) == CALLBACK_SUCCESS,
                "Balancer flashloan for module two failed"
            );
        } else {
            revert("Nonexistent Module!");
        }
        _tokens[0].safeTransferFrom(executor, balancerVault, _amounts[0] + _fees[0]);
    }
}
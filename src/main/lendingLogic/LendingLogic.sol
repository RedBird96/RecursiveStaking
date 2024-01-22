// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPoolV2} from "../../interfaces/aave/v2/IPoolV2.sol";
import {IPoolV3} from "../../interfaces/aave/v3/IPoolV3.sol";
import {IAaveOracle} from "../../interfaces/aave/IAaveOracle.sol";
import {IVariableDebtToken} from "../../interfaces/aave/IVariableDebtToken.sol";
import {ICWETHV3} from "../../interfaces/compound/v3/ICWETHV3.sol";
import {IMorphoAaveV2} from "../../interfaces/morpho/IMorphoAaveV2.sol";
import {IMorphoAaveLens} from "../../interfaces/morpho/IMorphoAaveLens.sol";
import {IWstETH} from "../../interfaces/lido/IWstETH.sol";
import {BasicLogic} from "./base/BasicLogic.sol";
import {ILendingLogic} from "./base/ILendingLogic.sol";
import {console} from "lib/forge-std/src/console.sol";

/**
 * @title LendingLogic contract
 * @notice This contract encompasses all the content related to strategy pools
 * and lending operations involved.
 * @dev Due to significant ABI differences among different lending protocols,
 * this approach aims to unify the ABIs of lending protocols and differentiate
 * them using IDs during contract invocation. This increases the flexibility of
 * contract calls.
 */
contract LendingLogic is BasicLogic, ILendingLogic {
    using SafeERC20 for IERC20;

    string public constant ERROR_ID = "ERROR_ID!";

    //Ethereum
    // address public constant WETH_ADDR = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    // address public constant STETH_ADDR = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    // address public constant WSTETH_ADDR = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    //Arbitrum
    address public constant WETH_ADDR = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant WSTETH_ADDR = 0x5979D7b546E38E414F7E9822514be443A4800529;
    IWstETH internal constant WSTETH = IWstETH(WSTETH_ADDR);

    // aave v2
    address public constant A_STETH_ADDR_AAVEV2 = 0x1982b2F5814301d4e9a8b0201555376e62F82428;
    address public constant D_WETH_ADDR_AAVEV2 = 0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;
    address public constant aaveWethGatewayV2 = 0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04;
    IAaveOracle public constant aaveOracleV2 = IAaveOracle(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9);
    IPoolV2 public constant aavePoolV2 = IPoolV2(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    // aave v3
    //Ethreum
    // address public constant A_WSTETH_ADDR_AAVEV3 = 0x0B925eD163218f6662a35e0f0371Ac234f9E9371;
    // address public constant D_WETH_ADDR_AAVEV3 = 0xeA51d7853EEFb32b6ee06b1C12E6dcCA88Be0fFE;
    // address public constant aaveWethGatewayV3 = 0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C;
    // IAaveOracle public constant aaveOracleV3 = IAaveOracle(0x54586bE62E3c3580375aE3723C145253060Ca0C2);
    // IPoolV3 public constant aavePoolV3 = IPoolV3(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    //Arbitrum
    address public constant A_WSTETH_ADDR_AAVEV3 = 0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf;
    address public constant D_WETH_ADDR_AAVEV3 = 0x77CA01483f379E58174739308945f044e1a764dc;
    IAaveOracle public constant aaveOracleV3 = IAaveOracle(0xb56c2F0B653B2e0b10C9b928C8580Ac5Df02C7C7);
    IPoolV3 public constant aavePoolV3 = IPoolV3(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
    // compound v3
    ICWETHV3 public constant compoundWethComet = ICWETHV3(0xA17581A9E3356d9A858b789D68B4d866e593aE94);
    // morpho-aaveV2
    address public constant A_WETH_ADDR_AAVEV2 = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    IMorphoAaveV2 public constant morphoPool = IMorphoAaveV2(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0);
    IMorphoAaveLens public constant morphoAaveLens = IMorphoAaveLens(0x507fA343d0A90786d86C7cd885f5C49263A91FF4);

    /**
     * @dev The method for executing a deposit in the lending protocol, where 
     * the strategy pool will delegatecall to this method.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _asset The type of asset being deposited in this transaction.
     * @param _amount The amount of asset being deposited in this transaction.
     */
    function deposit(uint8 _protocolId, address _asset, uint256 _amount) external override onlyDelegation {
        require(_asset == WSTETH_ADDR, "Wrong asset!");
        if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV2)) {
            aavePoolV2.deposit(_asset, _amount, address(this), 0);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV3)) {
            // uint256 wst_ = WSTETH.wrap(_amount);
            aavePoolV3.supply(WSTETH_ADDR, _amount, address(this), 0);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_COMPOUNDV3)) {
            uint256 wst_ = WSTETH.wrap(_amount);
            compoundWethComet.supply(WSTETH_ADDR, wst_);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_MORPHO_AAVEV2)) {
            morphoPool.supply(A_STETH_ADDR_AAVEV2, _amount);
        } else {
            revert(ERROR_ID);
        }
    }

    /**
     * @dev The method for executing a withdraw in the lending protocol, where 
     * the strategy pool will delegatecall to this method.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _asset The type of asset being withdrawn in this transaction.
     * @param _amount The amount of asset being withdrawn in this transaction.
     */
    function withdraw(uint8 _protocolId, address _asset, uint256 _amount) external override onlyDelegation {
        require(_asset == WSTETH_ADDR, "Wrong asset!");
        if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV2)) {
            aavePoolV2.withdraw(_asset, _amount, address(this));
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV3)) {
            /// @dev If you don't add 1, it will return 1wei less steth than expected.
            // uint256 withdraw_ = WSTETH.getWstETHByStETH(_amount + 1);
            aavePoolV3.withdraw(WSTETH_ADDR, _amount, address(this));
            // WSTETH.unwrap(withdraw_);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_COMPOUNDV3)) {
            uint256 withdraw_ = WSTETH.getWstETHByStETH(_amount + 1);
            compoundWethComet.withdraw(WSTETH_ADDR, withdraw_);
            WSTETH.unwrap(withdraw_);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_MORPHO_AAVEV2)) {
            morphoPool.withdraw(A_STETH_ADDR_AAVEV2, _amount);
        } else {
            revert(ERROR_ID);
        }
    }

    /**
     * @dev The method for executing a borrow in the lending protocol, where 
     * the strategy pool will delegatecall to this method.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _asset The type of asset being borrowed in this transaction.
     * @param _amount The amount of asset being borrowed in this transaction.
     */
    function borrow(uint8 _protocolId, address _asset, uint256 _amount) external override onlyDelegation {
        require(_asset == WETH_ADDR, "Wrong asset!");
        if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV2)) {
            aavePoolV2.borrow(_asset, _amount, 2, 0, address(this));
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV3)) {
            aavePoolV3.borrow(_asset, _amount, 2, 0, address(this));
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_COMPOUNDV3)) {
            compoundWethComet.withdraw(_asset, _amount);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_MORPHO_AAVEV2)) {
            morphoPool.borrow(A_WETH_ADDR_AAVEV2, _amount);
        } else {
            revert(ERROR_ID);
        }
    }

    /**
     * @dev The method for executing a repayment in the lending protocol, where 
     * the strategy pool will delegatecall to this method.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _asset The type of asset being repaid in this transaction.
     * @param _amount The amount of asset being repaid in this transaction.
     */
    function repay(uint8 _protocolId, address _asset, uint256 _amount) external override onlyDelegation {
        require(_asset == WETH_ADDR, "Wrong asset!");
        if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV2)) {
            aavePoolV2.repay(_asset, _amount, 2, address(this));
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV3)) {
            aavePoolV3.repay(_asset, _amount, 2, address(this));
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_COMPOUNDV3)) {
            compoundWethComet.supply(_asset, _amount);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_MORPHO_AAVEV2)) {
            morphoPool.repay(A_WETH_ADDR_AAVEV2, _amount);
        } else {
            revert(ERROR_ID);
        }
    }

    /**
     * @dev The method for allowing entry into a specified lending protocol,
     * where the strategy pool will delegatecall to this method.
     * @param _protocolId The index of the lending protocol within this contract.
     */
    function enterProtocol(uint8 _protocolId) external override onlyDelegation {
        if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV2)) {
            IERC20(WETH_ADDR).safeIncreaseAllowance(address(aavePoolV2), type(uint256).max);
            IERC20(WSTETH_ADDR).safeIncreaseAllowance(address(aavePoolV2), type(uint256).max);
            IERC20(A_STETH_ADDR_AAVEV2).safeIncreaseAllowance(address(aavePoolV2), type(uint256).max);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV3)) {
            IERC20(WETH_ADDR).safeIncreaseAllowance(address(aavePoolV3), type(uint256).max);
            IERC20(WSTETH_ADDR).safeIncreaseAllowance(address(aavePoolV3), type(uint256).max);
            IERC20(A_WSTETH_ADDR_AAVEV3).safeIncreaseAllowance(address(aavePoolV3), type(uint256).max);
            aavePoolV3.setUserEMode(1);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_COMPOUNDV3)) {
            IERC20(WETH_ADDR).safeIncreaseAllowance(address(compoundWethComet), type(uint256).max);
            IERC20(WSTETH_ADDR).safeIncreaseAllowance(address(compoundWethComet), type(uint256).max);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_MORPHO_AAVEV2)) {
            IERC20(WSTETH_ADDR).safeIncreaseAllowance(address(morphoPool), type(uint256).max);
            IERC20(WETH_ADDR).safeIncreaseAllowance(address(morphoPool), type(uint256).max);
        } else {
            revert(ERROR_ID);
        }
    }

    /**
     * @dev The method for disallowing entry into a specified lending protocol,
     * where the strategy pool will delegatecall to this method.
     * @param _protocolId The index of the lending protocol within this contract.
     */
    function exitProtocol(uint8 _protocolId) external override onlyDelegation {
        if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV2)) {
            IERC20(WETH_ADDR).safeApprove(address(aavePoolV2), 0);
            IERC20(WSTETH_ADDR).safeApprove(address(aavePoolV2), 0);
            IERC20(A_STETH_ADDR_AAVEV2).safeApprove(address(aavePoolV2), 0);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV3)) {
            IERC20(WETH_ADDR).safeApprove(address(aavePoolV3), 0);
            IERC20(WSTETH_ADDR).safeApprove(address(aavePoolV3), 0);
            IERC20(A_WSTETH_ADDR_AAVEV3).safeApprove(address(aavePoolV3), 0);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_COMPOUNDV3)) {
            IERC20(WETH_ADDR).safeApprove(address(compoundWethComet), 0);
            IERC20(WSTETH_ADDR).safeApprove(address(compoundWethComet), 0);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_MORPHO_AAVEV2)) {
            IERC20(WSTETH_ADDR).safeApprove(address(morphoPool), 0);
            IERC20(WETH_ADDR).safeApprove(address(morphoPool), 0);
        } else {
            revert(ERROR_ID);
        }
    }

    /**
     * @dev Retrieve the maximum amount of ETH that an account address can still
     * borrow in the lending protocol.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _account The account address.
     * @return availableBorrowsETH The maximum amount of ETH that can still be borrowed.
     */
    function getAvailableBorrowsETH(uint8 _protocolId, address _account)
        public
        view
        override
        returns (uint256 availableBorrowsETH)
    {
        if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV2)) {
            (,, availableBorrowsETH,,,) = aavePoolV2.getUserAccountData(_account);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV3)) {
            (,, uint256 availableBorrowsInUsd_,,,) = aavePoolV3.getUserAccountData(_account);
            if (availableBorrowsInUsd_ > 0) {
                uint256 wEthPrice_ = aaveOracleV3.getAssetPrice(WETH_ADDR);
                availableBorrowsETH = availableBorrowsInUsd_ * 1e18 / wEthPrice_;
            }
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_COMPOUNDV3)) {
            ICWETHV3.AssetInfo memory assetInfo_ = compoundWethComet.getAssetInfoByAddress(WSTETH_ADDR);
            uint256 price_ = compoundWethComet.getPrice(assetInfo_.priceFeed);
            uint256 collateralBalance_ = compoundWethComet.collateralBalanceOf(_account, WSTETH_ADDR);
            uint256 borrowedBalance_ = compoundWethComet.borrowBalanceOf(_account);
            availableBorrowsETH =
                (collateralBalance_ * price_ * assetInfo_.borrowCollateralFactor) / 1e26 - borrowedBalance_;
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_MORPHO_AAVEV2)) {
            (, availableBorrowsETH) = morphoAaveLens.getUserMaxCapacitiesForAsset(_account, A_WETH_ADDR_AAVEV2);
        } else {
            revert(ERROR_ID);
        }
    }

    /**
     * @dev Retrieve the maximum amount of stETH that an account address can still
     * withdraw in the lending protocol.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _account The account address.
     * @return maxWithdrawsWStETH The maximum amount of wstETH that can still be withdrawn.
     */
    function getAvailableWithdrawsStETH(uint8 _protocolId, address _account)
        public
        view
        override
        returns (uint256 maxWithdrawsWStETH)
    {
        if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV2)) {
            (uint256 colInETH_, uint256 debtInETH_,,, uint256 ltv_,) = aavePoolV2.getUserAccountData(_account);
            uint256 aavePrice_ = aaveOracleV2.getAssetPrice(WSTETH_ADDR);
            if (colInETH_ > 0) {
                maxWithdrawsWStETH = colInETH_ > (debtInETH_ * 1e4) / ltv_
                    ? ((colInETH_ - (debtInETH_ * 1e4) / ltv_) * 1e18) / aavePrice_
                    : 0;
            }
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV3)) {
            (uint256 colInUsd_, uint256 debtInUsd_,,, uint256 ltv_,) = aavePoolV3.getUserAccountData(_account);
            if (colInUsd_ > 0) {
                uint256 colMin_ = debtInUsd_ * 1e4 / ltv_;
                uint256 maxWithdrawsInUsd_ = colInUsd_ > colMin_ ? colInUsd_ - colMin_ : 0;
                uint256 wstEthPrice_ = aaveOracleV3.getAssetPrice(WSTETH_ADDR);
                maxWithdrawsWStETH = maxWithdrawsInUsd_ * 1e18 / wstEthPrice_;
            }
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_COMPOUNDV3)) {
            ICWETHV3.AssetInfo memory assetInfo_ = compoundWethComet.getAssetInfoByAddress(WSTETH_ADDR);
            uint256 price_ = compoundWethComet.getPrice(assetInfo_.priceFeed);
            uint256 collateralBalance_ = compoundWethComet.collateralBalanceOf(_account, WSTETH_ADDR);
            uint256 borrowedBalance_ = compoundWethComet.borrowBalanceOf(_account);
            uint256 collateralMin_ = (borrowedBalance_ * 1e26) / (assetInfo_.borrowCollateralFactor * price_);
            uint256 maxWithdrawsWstETH_ = collateralBalance_ - collateralMin_;
            uint256 stEthPerToken_ = WSTETH.stEthPerToken();
            maxWithdrawsWStETH = (maxWithdrawsWstETH_ * stEthPerToken_) / 1e18;
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_MORPHO_AAVEV2)) {
            (maxWithdrawsWStETH,) = morphoAaveLens.getUserMaxCapacitiesForAsset(_account, A_STETH_ADDR_AAVEV2);
        } else {
            revert(ERROR_ID);
        }
    }

    /**
     * @dev Retrieve the debt collateralization ratio of the account in the lending protocol,
     * using the oracle associated with that lending protocol.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _account The account address.
     * @return ratio The debt collateralization ratio, where 1e18 represents 100%.
     */
    function getProtocolCollateralRatio(uint8 _protocolId, address _account)
        public
        view
        override
        returns (uint256 ratio)
    {
        if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV2)) {
            (uint256 totalCollateralETH_, uint256 totalDebtETH_,,,,) = aavePoolV2.getUserAccountData(_account);
            ratio = totalCollateralETH_ == 0 ? 0 : totalDebtETH_ * 1e18 / totalCollateralETH_;
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV3)) {
            (uint256 totalCollateralBase_, uint256 totalDebtBase_,,,,) = aavePoolV3.getUserAccountData(_account);
            ratio = totalCollateralBase_ == 0 ? 0 : totalDebtBase_ * 1e18 / totalCollateralBase_;
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_COMPOUNDV3)) {
            ICWETHV3.AssetInfo memory assetInfo_ = compoundWethComet.getAssetInfoByAddress(WSTETH_ADDR);
            uint256 price_ = compoundWethComet.getPrice(assetInfo_.priceFeed);
            uint256 collateralBalance_ = compoundWethComet.collateralBalanceOf(_account, WSTETH_ADDR);
            uint256 borrowedBalance_ = compoundWethComet.borrowBalanceOf(_account);
            ratio = collateralBalance_ == 0 ? 0 : borrowedBalance_ * 1e18 / (collateralBalance_ * price_ / 1e8);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_MORPHO_AAVEV2)) {
            (uint256 collateralEth,,, uint256 debtEth) = morphoAaveLens.getUserBalanceStates(_account);
            ratio = collateralEth == 0 ? 0 : debtEth * 1e18 / collateralEth;
        } else {
            revert(ERROR_ID);
        }
    }

    /**
     * @dev Retrieve the amount of WETH required for the flash loan in this operation.
     * When increasing leverage, it is also possible to deposit stETH into the lending
     * protocol simultaneously. When decreasing leverage, it is also possible to withdraw
     * stETH from the lending protocol simultaneously.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _account The account address.
     * @param _isDepositOrWithdraw Whether an additional deposit of stETH is required.
     * @param _depositOrWithdraw The amount of stETH to be deposited or withdrawn.
     * @param _safeRatio The target collateralization ratio that the strategy pool needs to achieve.
     * @return isLeverage Returning "true" indicates the need to increase leverage, while returning
     * "false" indicates the need to decrease leverage.
     * @return loanAmount The amount of flash loan required for this transaction.
     */
    function getProtocolLeverageAmount(
        uint8 _protocolId,
        address _account,
        bool _isDepositOrWithdraw,
        uint256 _depositOrWithdraw,
        uint256 _safeRatio
    ) public view override returns (bool isLeverage, uint256 loanAmount) {
        uint256 totalCollateralETH_;
        uint256 totalDebtETH_;
        uint256 depositOrWithdrawInETH_;
        if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV2)) {
            uint256 stPrice_ = aaveOracleV2.getAssetPrice(WSTETH_ADDR);
            uint256 ethPrice_ = aaveOracleV2.getAssetPrice(WETH_ADDR);
            (totalCollateralETH_, totalDebtETH_,,,,) = aavePoolV2.getUserAccountData(_account);
            depositOrWithdrawInETH_ = _depositOrWithdraw * stPrice_ / ethPrice_;
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV3)) {
            uint256 wstPrice_ = aaveOracleV3.getAssetPrice(WSTETH_ADDR);
            uint256 ethPrice_ = aaveOracleV3.getAssetPrice(WETH_ADDR);
            totalCollateralETH_ = IERC20(A_WSTETH_ADDR_AAVEV3).balanceOf(_account) * wstPrice_ / ethPrice_;
            totalDebtETH_ = IERC20(D_WETH_ADDR_AAVEV3).balanceOf(_account);
            depositOrWithdrawInETH_ = _depositOrWithdraw * wstPrice_ / ethPrice_;
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_COMPOUNDV3)) {
            ICWETHV3.AssetInfo memory assetInfo_ = compoundWethComet.getAssetInfoByAddress(WSTETH_ADDR);
            uint256 price_ = compoundWethComet.getPrice(assetInfo_.priceFeed);
            totalCollateralETH_ = compoundWethComet.collateralBalanceOf(_account, WSTETH_ADDR) * price_ / 1e8;
            totalDebtETH_ = compoundWethComet.borrowBalanceOf(_account);
            depositOrWithdrawInETH_ = _depositOrWithdraw * price_ / 1e8;
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_MORPHO_AAVEV2)) {
            (totalCollateralETH_,,, totalDebtETH_) = morphoAaveLens.getUserBalanceStates(_account);
            uint256 stPrice_ = aaveOracleV2.getAssetPrice(WSTETH_ADDR);
            depositOrWithdrawInETH_ = _depositOrWithdraw * stPrice_ / 1e18;
        } else {
            revert(ERROR_ID);
        }
        totalCollateralETH_ = _isDepositOrWithdraw
            ? (totalCollateralETH_ + depositOrWithdrawInETH_)
            : (totalCollateralETH_ - depositOrWithdrawInETH_);
        if (totalCollateralETH_ != 0) {
            uint256 ratio = totalCollateralETH_ == 0 ? 0 : totalDebtETH_ * 1e18 / totalCollateralETH_;
            isLeverage = ratio < _safeRatio ? true : false;
            if (isLeverage) {
                loanAmount = (_safeRatio * totalCollateralETH_ - totalDebtETH_ * 1e18) / (1e18 - _safeRatio);
            } else {
                loanAmount = (totalDebtETH_ * 1e18 - _safeRatio * totalCollateralETH_) / (1e18 - _safeRatio);
            }
        }
    }

    /**
     * @dev Retrieve the collateral and debt quantities of the account in the lending protocol.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _account The account address.
     * @return wstEthAmount The amount of wstETH collateral.
     * @return debtEthAmount The amount of ETH debt.
     */
    function getProtocolAccountData(uint8 _protocolId, address _account)
        public
        view
        override
        returns (uint256 wstEthAmount, uint256 debtEthAmount)
    {
        if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV2)) {
            wstEthAmount = IERC20(A_STETH_ADDR_AAVEV2).balanceOf(_account);
            debtEthAmount = IERC20(D_WETH_ADDR_AAVEV2).balanceOf(_account);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_AAVEV3)) {
            wstEthAmount = IERC20(A_WSTETH_ADDR_AAVEV3).balanceOf(_account);
            debtEthAmount = IERC20(D_WETH_ADDR_AAVEV3).balanceOf(_account);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_COMPOUNDV3)) {
            wstEthAmount = compoundWethComet.collateralBalanceOf(_account, WSTETH_ADDR);
            debtEthAmount = compoundWethComet.borrowBalanceOf(_account);
        } else if (_protocolId == uint8(PROTOCOL.PROTOCOL_MORPHO_AAVEV2)) {
            uint256 stPrice_ = aaveOracleV2.getAssetPrice(WSTETH_ADDR);
            uint256 collateralEth;
            (collateralEth,,, debtEthAmount) = morphoAaveLens.getUserBalanceStates(_account);
            wstEthAmount = collateralEth * 1e18 / stPrice_;
        } else {
            revert(ERROR_ID);
        }
    }

    /**
     * @dev Retrieve the amount of assets in all lending protocols involved 
     * in this contract for the account.
     * @param _account The account address.
     * @return totalAssets The total amount of collateral.
     * @return totalDebt The total amount of debt.
     * @return netAssets The total amount of net assets.
     * @return aggregatedRatio The aggregate collateral-to-debt ratio.
     */
    function getNetAssetsInfo(address _account)
        public
        view
        override
        returns (uint256 totalAssets, uint256 totalDebt, uint256 netAssets, uint256 aggregatedRatio)
    {
        uint256 protocolAsset_;
        uint256 protocolDebt_;
        for (uint8 protocolId_ = 0; protocolId_ <= uint8(PROTOCOL.PROTOCOL_MORPHO_AAVEV2); protocolId_++) {
            (protocolAsset_, protocolDebt_) = getProtocolAccountData(protocolId_, _account);
            totalAssets += protocolAsset_;
            totalDebt += protocolDebt_;
        }
        netAssets = totalAssets - totalDebt;
        aggregatedRatio = totalAssets == 0 ? 0 : (totalDebt * 1e18) / totalAssets;
    }
}
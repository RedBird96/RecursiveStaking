// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/lido/IWstETH.sol";
import "../interfaces/weth/IWETH.sol";

/**
 * @title VaultStETH contract
 * @author Cian
 * @dev This contract is the logical implementation of the vault,
 * and its main purpose is to provide users with a gateway for depositing
 * and withdrawing funds and to manage user shares. 
 */
contract VaultStETH is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, ERC4626Upgradeable {
    using SafeERC20 for IWstETH;
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public immutable implementationAddress;
    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant STETH_ADDR = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant WSTETH_ADDR = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    IERC20Upgradeable internal constant STETH_CONTRACT = IERC20Upgradeable(STETH_ADDR);

    IStrategy public strategy;
    // Who to receive the fee.
    address public feeReceiver;
    // Market capacity.
    uint256 public marketCapacity;
    // Management fee in percentage.
    uint256 public managementFeePercentage;
    // Management fee per second in percentage.
    uint256 public managementFeePercentagePerSec;
    // Exit fee in percentage.
    uint256 public exitFeeRate;
    // Deleverage exit fee in percentage.
    uint256 public deleverageExitFeeRate;
    // The last time the fees are charged.
    uint256 public lastTimestamp;
    // Accumulated management fee as lp that can be claimed.
    uint256 public managementFeeAcc;

    event UpdateStrategy(address oldStrategy, address newStrategy);
    event UpdateManagementFee(uint256 oldManagementFee, uint256 newManagementFee);
    event UpdateExitFeeRate(uint256 oldExitFeeRate, uint256 newExitFeeRate);
    event UpdateDeleverageExitFeeRate(uint256 oldDeleverageExitFeeRate, uint256 newDeleverageExitFeeRate);
    event UpdateFeeReceiver(address oldFeeReceiver, address newFeeReceiver);
    event UpdateMarketCapacity(uint256 oldCapacityLimit, uint256 newCapacityLimit);
    event DeleverageWithdraw(
        uint8 protocolId,
        address owner,
        address receiver,
        address token,
        uint256 assetsGet,
        uint256 shares,
        uint256 flashloanSelector
    );

    constructor() {
        implementationAddress = address(this);
    }

    /**
     * @dev Ensure that the contract call is executed through the EIP-1967 proxy.
     */
    modifier onlyProxy() {
        require(address(this) != implementationAddress, "!proxy");
        _;
    }

    /**
     * @dev Ensure that this method is called by an address with permission.
     */
    modifier onlyAuthorized() {
        require(msg.sender == owner() || msg.sender == feeReceiver, "!Authorized");
        _;
    }

    /**
     * @dev Initialize various parameters of the Vault contract.
     * @param _strategy The contract address of the strategy pool, which manages all the assets.
     * @param _feeReceiver The address of the recipient for management fees.
     * @param _marketCapacity The maximum investment capacity.
     * @param _managementFeePercentage The annualized management fee rate.
     * @param _exitFeeRate The percentage of exit fee.
     * @param _deleverageExitFeeRate The percentage of exit fee for reducing leverage.
     */
    function initialize(
        address _strategy,
        address _feeReceiver,
        uint256 _marketCapacity,
        uint256 _managementFeePercentage,
        uint256 _exitFeeRate,
        uint256 _deleverageExitFeeRate
    ) public initializer onlyProxy {
        __Ownable_init();
        __ERC20_init("CIAN ETH-stETH strategy pool", "ciETH");
        __ERC4626_init(STETH_CONTRACT);
        strategy = IStrategy(_strategy);
        require(_feeReceiver != address(0), "Fee receiver cannot be zero address!");
        feeReceiver = _feeReceiver;
        // The minimum position size is 100.
        require(_marketCapacity > 100e18, "Wrong marketCapacity!");
        marketCapacity = _marketCapacity;
        // 0~10000 ---- 0%～100% per year.
        // Management fee, the maximum annualized rate is 2%.
        require(_managementFeePercentage >= 0 && _managementFeePercentage <= 200, "Management fee exceeds the limit!");
        managementFeePercentage = _managementFeePercentage;
        managementFeePercentagePerSec = (_managementFeePercentage * 1e18) / (365.25 days * 1e4);
        // The maximum fee for withdrawing from the idle treasury is 1.2%.
        require(_exitFeeRate >= 1 && _exitFeeRate <= 120, "Exit fee exceeds the limit!");
        exitFeeRate = _exitFeeRate;
        // The maximum fee for withdrawing from the leveraged treasury is 1.2%.
        require(_deleverageExitFeeRate >= 1 && _deleverageExitFeeRate <= 120, "Deleverage Exit fee exceeds the limit!");
        deleverageExitFeeRate = _deleverageExitFeeRate;
        STETH_CONTRACT.safeIncreaseAllowance(_strategy, type(uint256).max);
        STETH_CONTRACT.safeIncreaseAllowance(WSTETH_ADDR, type(uint256).max);
        lastTimestamp = block.timestamp;
    }

    /**
     * @dev Update the contract address of the strategy pool.
     * @param _newStrategy The new contract address.
     */
    function updateStrategy(address _newStrategy) public onlyOwner {
        require(_newStrategy != address(0), "Strategy error!");
        emit UpdateStrategy(address(strategy), _newStrategy);
        strategy = IStrategy(_newStrategy);
    }

    /**
     * @dev Update the address of the recipient for management fees.
     * @param _feeReceiver The new address of the recipient for management fees.
     */
    function updateFeeReceiver(address _feeReceiver) public onlyOwner {
        managementFeeClaim();
        emit UpdateFeeReceiver(feeReceiver, _feeReceiver);
        feeReceiver = _feeReceiver;
    }

    /**
     * @dev Update the size of the pool's capacity.
     * @param _newCapacityLimit The new size of the capacity.
     */
    function updateMarketCapacity(uint256 _newCapacityLimit) public onlyOwner {
        require(_newCapacityLimit > marketCapacity, "Unsupported!");
        emit UpdateMarketCapacity(marketCapacity, _newCapacityLimit);
        marketCapacity = _newCapacityLimit;
    }

    /**
     * @dev Update the management fee rate.
     * @param _newManagementFeePercentage The new rate.
     */
    function updateManagementFee(uint256 _newManagementFeePercentage) public onlyOwner {
        require(
            _newManagementFeePercentage >= 0 && _newManagementFeePercentage <= 200, "Management fee exceeds the limit!"
        );
        emit UpdateManagementFee(managementFeePercentage, _newManagementFeePercentage);
        managementFeePercentagePerSec = (_newManagementFeePercentage * 1e18) / (365.25 days * 1e4);
        managementFeePercentage = _newManagementFeePercentage;
    }

    /**
     * @dev Update the exit fee rate.
     * @param _exitFeeRate The new rate.
     */
    function updateExitFeeRate(uint256 _exitFeeRate) public onlyOwner {
        require(_exitFeeRate >= 1 && _exitFeeRate <= 120, "Exit fee exceeds the limit!");
        emit UpdateExitFeeRate(exitFeeRate, _exitFeeRate);
        exitFeeRate = _exitFeeRate;
    }

    /**
     * @dev Update the fee rate for withdrawing asset by reducing leverage.
     * @param _deleverageExitFeeRate The new rate.
     */
    function updateDeleverageExitFeeRate(uint256 _deleverageExitFeeRate) public onlyOwner {
        require(_deleverageExitFeeRate >= 1 && _deleverageExitFeeRate <= 120, "Deleverage Exit fee exceeds the limit!");
        emit UpdateDeleverageExitFeeRate(deleverageExitFeeRate, _deleverageExitFeeRate);
        deleverageExitFeeRate = _deleverageExitFeeRate;
    }

    /**
     * @dev Retrieve the amount of assets in the strategy pool.
     */
    function balance() public view returns (uint256) {
        return IStrategy(strategy).getNetAssets();
    }

    /**
     * @dev Retrieve the amount of the exit fee.
     * @param _stETHAmount The amount of stETH to be withdrawn.
     * @return The exit fee to be deducted.
     *
     */
    function getWithdrawFee(uint256 _stETHAmount) public view returns (uint256) {
        uint256 withdrawFee = (_stETHAmount * exitFeeRate) / 1e4;

        return withdrawFee;
    }

    /**
     * @dev Retrieve the amount of the exit fee for reducing leverage.
     * @param _stETHAmount The amount of stETH to be withdrawn.
     * @return The exit fee to be deducted.
     */
    function getDeleverageWithdrawFee(uint256 _stETHAmount) public view returns (uint256) {
        uint256 withdrawFee = (_stETHAmount * deleverageExitFeeRate) / 1e4;

        return withdrawFee;
    }

    /**
     * @dev Retrieve the amount of stETH required for performing a swap during
     * the withdrawal for reducing leverage.
     * @param _stETHAmount The amount of stETH to be withdrawn if leverage is not being reduced.
     * @param _isETH "True" indicates that ETH is being withdrawn, otherwise it is stETH.
     * @return amount The amount of stETH required for the swap.
     */
    function getDeleverageWithdrawAmount(uint256 _stETHAmount, bool _isETH, uint8 _protocolId)
        public
        view
        returns (uint256 amount)
    {
        uint256 afterWithdrawFee_ = _stETHAmount - getDeleverageWithdrawFee(_stETHAmount);
        // If you plan to take out afterWithdrawFee_ stETH from the vault, the amount stETH will be exchanged for ETH.
        amount = strategy.getDeleverageAmount(afterWithdrawFee_, _protocolId);
        if (_isETH) {
            // If the withdrawal is ETH, then the stETH that should have been withdrawn will also be exchanged for ETH.
            amount += afterWithdrawFee_;
        }
    }

    /**
     * @dev Retrieve the amount of assets in the strategy pool.
     */
    function totalAssets() public view virtual override returns (uint256) {
        return (strategy.exchangePrice() * totalSupply()) / 1e18;
    }

    /**
     * @dev Override the deposit method of ERC4626 to perform capacity verification and
     * transfer assets to the strategy contract during the deposit process.
     * @param _caller The caller of the contract.
     * @param _receiver The recipient of the share tokens.
     * @param _assets The amount of stETH being deposited.
     * @param _shares The amount of share tokens obtained.
     */
    function _deposit(address _caller, address _receiver, uint256 _assets, uint256 _shares) internal override {
        require(_assets + totalAssets() <= marketCapacity, "Exceeding market capacity.");
        STETH_CONTRACT.safeTransferFrom(_caller, address(this), _assets);
        _mint(_receiver, _shares);
        strategy.deposit(_assets);
        emit Deposit(_caller, _receiver, _assets, _shares);
    }

    /**
     * @dev The deposit method of ERC4626, with the parameter being the amount of assets.
     * @param _assets The amount of stETH being deposited.
     * @param _receiver The recipient of the share tokens.
     * @return shares The amount of share tokens obtained.
     */
    function deposit(uint256 _assets, address _receiver)
        public
        override
        whenNotPaused
        nonReentrant
        returns (uint256 shares)
    {
        if (_assets == type(uint256).max) {
            _assets = IERC20Upgradeable(STETH_ADDR).balanceOf(msg.sender);
        }
        shares = super.deposit(_assets, _receiver);
    }

    /**
     * @dev The withdrawal method of ERC4626, with the parameter being the amount of assets.
     * @param _assets The amount of assets to be withdrawn.
     * @param _receiver The recipient of the withdrawn assets.
     * @return shares The amount of share tokens consumed for the asset withdrawal.
     */
    function withdraw(uint256 _assets, address _receiver, address _owner)
        public
        override
        whenNotPaused
        nonReentrant
        returns (uint256 shares)
    {
        if (_assets == type(uint256).max) {
            _assets = maxWithdraw(_owner);
        } else {
            require(_assets <= maxWithdraw(_owner), "ERC4626: withdraw more than max");
        }
        shares = previewWithdraw(_assets);
        uint256 assetsAfterFee_ = _assets - getWithdrawFee(_assets);
        uint256 stGet_ = strategy.withdraw(assetsAfterFee_);

        _withdraw(msg.sender, _receiver, _owner, stGet_, shares);
    }

    /**
     * @dev The deposit method of ERC4626, with the parameter being the amount of share tokens.
     * @param _shares The amount of share tokens to be minted.
     * @param _receiver The recipient of the share tokens.
     * @return assets The amount of assets consumed.
     */
    function mint(uint256 _shares, address _receiver)
        public
        override
        whenNotPaused
        nonReentrant
        returns (uint256 assets)
    {
        assets = super.mint(_shares, _receiver);
    }

    /**
     * @dev The asset redemption method of ERC4626, with the parameter being the amount of share tokens.
     * @param _shares The amount of share tokens to be redeemed.
     * @param _receiver The address of the recipient for the redeemed assets.
     * @param _owner The owner of the redeemed share tokens.
     * @return assetsAfterFee The actual amount of assets redeemed.
     */
    function redeem(uint256 _shares, address _receiver, address _owner)
        public
        override
        whenNotPaused
        nonReentrant
        returns (uint256 assetsAfterFee)
    {
        if (_shares == type(uint256).max) {
            _shares = maxRedeem(_owner);
        } else {
            require(_shares <= maxRedeem(_owner), "ERC4626: redeem more than max");
        }
        uint256 assets_ = previewRedeem(_shares);
        assetsAfterFee = assets_ - getWithdrawFee(assets_);
        uint256 stGet_ = strategy.withdraw(assetsAfterFee);

        _withdraw(msg.sender, _receiver, _owner, stGet_, _shares);
    }

    /**
     * @dev When there is insufficient idle funds in the strategy pool,
     * users can opt to withdraw funds and reduce leverage in a specific lending protocol.
     * @param _protocolId The index number of the lending protocol.
     * @param _token The type of token to be redeemed.
     * @param _assets The original amount of assets that could be redeemed.
     * @param _swapData  The calldata for the 1inch exchange operation.
     * @param _swapGetMin The minimum amount of token to be obtained during the 1inch exchange operation.
     * @param _flashloanSelector The selection of the flash loan protocol.
     * @param _owner The owner of the redeemed share tokens.
     * @param _receiver The address of the recipient for the redeemed assets.
     * @return shares The amount of share tokens obtained.
     */
    function deleverageWithdraw(
        uint8 _protocolId,
        address _token,
        uint256 _assets,
        bytes memory _swapData,
        uint256 _swapGetMin,
        uint256 _flashloanSelector,
        address _owner,
        address _receiver
    ) external whenNotPaused nonReentrant returns (uint256 shares) {
        if (_assets == type(uint256).max) {
            _assets = maxWithdraw(_owner);
        } else {
            require(_assets <= maxWithdraw(_owner), "ERC4626: withdraw more than max");
        }
        shares = previewWithdraw(_assets);
        uint256 assetsAfterFee_ = _assets - getDeleverageWithdrawFee(_assets);
        if (msg.sender != _owner) {
            _spendAllowance(_owner, msg.sender, shares);
        }

        bool _isETH = (_token == ETH_ADDR || _token == WETH_ADDR) ? true : false;
        uint256 assetsGet_ = strategy.deleverageAndWithdraw(
            _protocolId, assetsAfterFee_, _swapData, _swapGetMin, _isETH, _flashloanSelector
        );
        _burn(_owner, shares);
        if (_token == STETH_ADDR) {
            STETH_CONTRACT.safeTransfer(_receiver, assetsGet_);
        } else if (_token == WSTETH_ADDR) {
            uint256 withdraw_ = IWstETH(WSTETH_ADDR).wrap(assetsGet_);
            IWstETH(WSTETH_ADDR).safeTransfer(_receiver, withdraw_);
        } else if (_token == WETH_ADDR) {
            IWETH(WETH_ADDR).safeTransfer(_receiver, assetsGet_);
        } else if (_token == ETH_ADDR) {
            IWETH(WETH_ADDR).withdraw(assetsGet_);
            Address.sendValue(payable(_receiver), assetsGet_);
        } else {
            revert("Token error.");
        }

        emit DeleverageWithdraw(_protocolId, _owner, _receiver, _token, assetsGet_, shares, _flashloanSelector);
    }

    /**
     * @dev Retrieve the amount of management fee share tokens that have not been minted yet.
     */
    function pendingManagementFee() public view returns (uint256) {
        if (totalSupply() == 0 || managementFeePercentage == 0) return 0;
        uint256 timeDiff_ = block.timestamp - lastTimestamp;

        return
            timeDiff_ > 0 ? ((totalSupply() - managementFeeAcc) * timeDiff_ * managementFeePercentagePerSec) / 1e18 : 0;
    }

    /**
     * @dev Retrieve the current total amount of management fee share tokens,
     * including those that are yet to be minted.
     */
    function currentManagementFee() public view returns (uint256) {
        return managementFeeAcc + pendingManagementFee();
    }

    /**
     * @dev Mint management fee share tokens.
     */
    function managementFeeSettle() public onlyAuthorized {
        if (managementFeePercentage == 0) return;
        uint256 pendingFeeShares_ = pendingManagementFee();
        if (pendingFeeShares_ != 0) {
            _mint(address(this), pendingFeeShares_);
            managementFeeAcc += pendingFeeShares_;
            lastTimestamp = block.timestamp;
        }
    }

    /**
     * @dev Redeem the corresponding assets using the management fee share tokens.
     */
    function managementFeeClaim() public onlyAuthorized {
        managementFeeSettle();
        uint256 assets_ = previewRedeem(managementFeeAcc);
        uint256 stGet_ = strategy.withdraw(assets_);
        _burn(address(this), managementFeeAcc);
        managementFeeAcc = 0;
        STETH_CONTRACT.safeTransfer(feeReceiver, stGet_);
    }

    /**
     * @dev Handle when someone else accidentally transfers assets to this contract.
     */
    function sweep(address _token) external onlyOwner {
        uint256 amount_ = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(owner(), amount_);
        uint256 ethbalance_ = address(this).balance;
        if (ethbalance_ > 0) {
            Address.sendValue(payable(owner()), ethbalance_);
        }
    }

    /**
     * @dev Pause user deposit and withdrawal operations.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Resume user deposit and withdrawal operations.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Retrieve the version number of the vault contract.
     */
    function getVersion() public pure returns (string memory) {
        return "v0.0.1";
    }

    receive() external payable {}
}
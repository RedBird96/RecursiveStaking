// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract StrategyDummyImplementation {
    // basic & ReadModule

    function WETH_ADDR() external view returns (address) {}

    function STETH_ADDR() external view returns (address) {}

    function WSTETH_ADDR() external view returns (address) {}

    function owner() external view returns (address) {}

    function lendingLogic() external view returns (address) {}

    function flashloanHelper() external view returns (address) {}

    function executor() external view returns (address) {}

    function vault() external view returns (address) {}

    function safeAggregatedRatio() external view returns (uint256) {}

    function safeProtocolRatio(uint8 _protocolId) external view returns (uint256) {}

    function exchangePrice() external view returns (uint256) {}

    function revenueExchangePrice() external view returns (uint256) {}

    function revenue() external view returns (uint256) {}

    function revenueRate() external view returns (uint256) {}

    function withdrawFeeRate() external view returns (uint256) {}

    function availableProtocol(uint8 _protocolId) external view returns (bool) {}

    function rebalancer(address _rebalancer) external view returns (bool) {}

    function getAvailableBorrowsETH(uint8 _protocolId) public view returns (uint256) {}

    function getAvailableWithdrawsStETH(uint8 _protocolId) public view returns (uint256) {}

    function getProtocolAccountData(uint8 _protocolId)
        external
        view
        returns (uint256 stEthAmount_, uint256 debtEthAmount_)
    {}

    function getNetAssetsInfo() public view returns (uint256, uint256, uint256, uint256) {}

    function getNetAssets() public view returns (uint256) {}

    function getProtocolNetAssets(uint8 _protocolId) public view returns (uint256) {}

    function getProtocolCollateralRatio(uint8 _protocolId) public view returns (uint256 protocolRatio_, bool isOK_) {}

    function getProtocolLeverageAmount(uint8 _protocolId, bool _isDepositOrWithdraw, uint256 _depositOrWithdraw)
        public
        view
        returns (bool isLeverage_, uint256 amount_)
    {}

    function getCurrentExchangePrice() public view returns (uint256 newExchangePrice_, uint256 newRevenue_) {}

    function getVersion() public pure returns (string memory) {}

    // AdminModule
    function initialize(
        uint256 _revenueRate,
        uint256 _safeAggregatedRatio,
        uint256[] memory _safeProtocolRatio,
        address[] memory _rebalancers,
        address _flashloanHelper,
        address _lendingLogic,
        address _feeReceiver
    ) external {}

    function enterProtocol(uint8 _protocolId) external {}

    function exitProtocol(uint8 _protocolId) external {}

    function setVault(address _vault) external {}

    function updateFeeReceiver(address _newFeeReceiver) public {}

    function updateLendingLogic(address _newLendingLogic) external {}

    function updateFlashloanHelper(address _newLendingLogic) external {}

    function updateRebalancer(address[] calldata _rebalancers, bool[] calldata _isAllowed) external {}

    function updateSafeAggregatedRatio(uint256 _newSafeAggregatedRatio) external {}

    function updateSafeProtocolRatio(uint8[] calldata _protocolId, uint256[] calldata _safeProtocolRatio) external {}

    function updateWithdrawFeeRate(uint256 _newWithdrawFeeRate) external {}

    function collectRevenue() external {}

    // LeverageModule
    function leverage(
        uint8 _protocolId,
        uint256 _stETHDepositAmount,
        uint256 _wEthDebtAmount,
        bytes calldata _swapData,
        uint256 _minimumAmount
    ) external {}

    function deleverage(
        uint8 _protocolId,
        uint256 _stETHWithdrawAmount,
        uint256 _wETHDebtAmount,
        bytes calldata _swapData,
        uint256 _minimumAmount
    ) external {}

    function getDeleverageAmount(uint256 _share, uint8 _protocolId) public view returns (uint256) {}

    function deleverageAndWithdraw(
        uint8 _protocolId,
        uint256 _withdrawShare,
        bytes calldata _swapData,
        uint256 _swapGetMin
    ) external returns (uint256) {}

    function onFlashLoanOne(address _initiator, address _token, uint256 _amount, uint256 _fee, bytes calldata _params)
        external
        returns (bytes32)
    {}

    function updateExchangePrice() external returns (uint256 newExchangePrice_, uint256 newRevenue_) {}

    // MigrateModule
    function migrate(
        uint8 _fromProtocolId,
        uint8 _toProtocolId,
        uint256 _stAmount,
        uint256 _debtAmount,
        uint256 _flashloanSelector
    ) external {}

    function onFlashLoanTwo(address _initiator, address _token, uint256 _amount, uint256 _fee, bytes calldata _params)
        external
        returns (bytes32)
    {}

    // UserModule
    function deposit(uint256 _stAmount) external returns (uint256 operateExchangePrice_) {}

    function withdraw(uint256 _stAmount) external returns (uint256 userStGet_) {}
}
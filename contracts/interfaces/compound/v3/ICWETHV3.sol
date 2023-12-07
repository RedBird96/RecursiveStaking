// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICWETHV3 {
    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }

    function collateralBalanceOf(address account, address asset) external view returns (uint128);

    function supply(address asset, uint256 amount) external;

    function withdraw(address asset, uint256 amount) external;

    function getAssetInfoByAddress(address asset) external view returns (AssetInfo memory);

    function getPrice(address priceFeed) external view returns (uint256);

    function borrowBalanceOf(address account) external view returns (uint256);
}
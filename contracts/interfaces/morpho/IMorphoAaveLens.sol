// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IMorphoAaveLens {
    /// @notice Returns the maximum amount available to withdraw & borrow for a given user, on a given market.
    /// @param _user The user to determine the capacities for.
    /// @param _poolToken The address of the market.
    /// @return withdrawable The maximum withdrawable amount of underlying token allowed (in underlying).
    /// @return borrowable The maximum borrowable amount of underlying token allowed (in underlying).
    function getUserMaxCapacitiesForAsset(address _user, address _poolToken)
        external
        view
        returns (uint256 withdrawable, uint256 borrowable);

    /// @notice Returns the collateral value, debt value and max debt value of a given user.
    /// @param _user The user to determine liquidity for.
    // returns The liquidity data of the user.
    // The collateral value (in ETH).
    // The maximum debt value allowed to borrow (in ETH).
    // The maximum debt value allowed before being liquidatable (in ETH).
    // The debt value (in ETH).
    function getUserBalanceStates(address _user)
        external
        view
        returns (uint256 collateralEth, uint256 borrowableEth, uint256 maxDebtEth, uint256 debtEth);

    /// @notice Returns the data related to `_poolToken` for the `_user`.
    /// @param _user The user to determine data for.
    /// @param _poolToken The address of the market.
    /// @param _oracle The oracle used.
    // return assetData The data related to this asset.
    // The number of decimals of the underlying token.
    // The token unit considering its decimals.
    // The liquidation threshold applied on this token (in basis point).
    // The LTV applied on this token (in basis point).
    // The price of the token (in ETH).
    // The collateral value of the asset (in ETH).
    // The debt value of the asset (in ETH).);
    function getUserLiquidityDataForAsset(address _user, address _poolToken, address _oracle)
        external
        view
        returns (
            uint256 decimals,
            uint256 tokenUnit,
            uint256 liquidationThreshold,
            uint256 ltv,
            uint256 underlyingPrice,
            uint256 collateralEth,
            uint256 debtEth
        );
}
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IAaveOracle {
    function getAssetPrice(address asset) external view returns (uint256);
}
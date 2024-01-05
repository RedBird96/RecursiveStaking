// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/contracts/interfaces/IERC3156FlashBorrower.sol";

interface IFlashloanHelper {
    enum PROVIDER {
        PROVIDER_AAVEV3,
        PROVIDER_BALANCER
    }

    function flashLoan(IERC3156FlashBorrower _receiver, address _token, uint256 _amount, bytes calldata _dataBytes)
        external
        returns (bool);
}
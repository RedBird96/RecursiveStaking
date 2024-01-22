// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/contracts/token/ERC20/ERC20.sol";
import  {SafeERC20} from "@openzeppelin/contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockToken is ERC20 {
    using SafeERC20 for IERC20;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20 (name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address account, uint256 amount) public virtual {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public virtual {
        _burn(account, amount);
    }
}
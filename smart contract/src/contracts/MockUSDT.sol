// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDT is ERC20("MockUSDT", "USDT"){
    function mint(address account, uint256 amount) external {
        _mint(account,amount);
    }
}
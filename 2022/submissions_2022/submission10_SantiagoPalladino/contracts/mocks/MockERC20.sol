// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
  constructor(address holder) ERC20("MockToken", "MCK") {
    _mint(holder, 10000 * 10 ** decimals());
  }
}

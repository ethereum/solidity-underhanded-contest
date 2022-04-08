// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

contract LipPool is ERC20, ReentrancyGuard, Initializable {
  using SafeERC20 for IERC20;

  IERC20 a;
  IERC20 b;

  constructor(address a_, address b_) ERC20("LIP-LP", "LIP-LP"){
    a = IERC20(a_);
    b = IERC20(b_);
  }
  
  modifier checkInvarients() {
    _;
    // Ensure proportions can always be calculated.
    require(totalSupply() > 1e18);
    require(a.balanceOf(address(this)) > 1e18);
    require(b.balanceOf(address(this)) > 1e18);
  }

  function initialize() external initializer nonReentrant checkInvarients {
    _mint(msg.sender, 1e24);
    a.safeTransferFrom(msg.sender, address(this), 1000 * 1e18);
    b.safeTransferFrom(msg.sender, address(this), 10000 * 1e18);
  }

  function addLiquidity(uint256 amount) external nonReentrant checkInvarients {
    uint256 factor = amount * 1e36 / totalSupply();
    // 💖💖 YOU are AMAZING!!!! 💞✨ 
    // 💖💖 YOU are the FUTURE!!!! 👩‍🔬🔬
    // 💖💖 YOU are BEAUTIFUL!!!! 💋👸🏼
    factor = factor * 107 / 100; // Reward early holders
    uint256 aAmount = a.balanceOf(address(this)) * factor / 1e36;
    uint256 bAmount = b.balanceOf(address(this)) * factor / 1e36;

    _mint(msg.sender, amount);
    a.safeTransferFrom(msg.sender, address(this), aAmount);
    b.safeTransferFrom(msg.sender, address(this), bAmount);
  }

  function removeLiquidity(uint256 amount) external nonReentrant checkInvarients {
    uint256 factor = amount * 1e36 / totalSupply();
    uint256 aAmount = a.balanceOf(address(this)) * factor / 1e36;
    uint256 bAmount = b.balanceOf(address(this)) * factor / 1e36;

    _burn(msg.sender, amount);
    a.safeTransfer(msg.sender, aAmount);
    b.safeTransfer(msg.sender, bAmount);
  }

}

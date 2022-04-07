//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface TokenStaker {
    function stake(address token, uint256 amount) external;

    function withdraw(address token, uint256 amount) external;
}

interface IVeryCoolPoolTokens {
    function withdraw(address from, address staker) external;
}

// Standard Liquidity Pool ala Uniswap plus Staking on Third Party. Only important logic
// is shown:
//   - Users staking and getting LP tokens will receive fees back
//   - Third party also generates rewards on LP tokens
//
contract VeryCoolPoolTokens is ERC20Burnable, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public tokenA;
    IERC20 public tokenB;

    mapping(address => uint256) public balanceOfA;
    mapping(address => uint256) public balanceOfB;

    constructor(address _tokenA, address _tokenB) ERC20("VeryCoolLP", "VCLP") {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function getEncodedData(uint128 amountA, uint128 amountB) external pure returns (bytes memory) {
        return abi.encode(amountA, amountB);
    }

    function deposit(
        address from,
        uint128 amountA,
        uint128 amountB,
        address staker
    ) external onlyOwner {
        balanceOfA[from] += amountA;
        balanceOfB[from] += amountB;

        // Very simple LP generation!
        uint256 lpAmount = amountA + amountB;
        _mint(address(this), amountA + amountB);
        _approve(address(this), staker, lpAmount);

        tokenA.safeTransferFrom(from, address(this), amountA);
        tokenB.safeTransferFrom(from, address(this), amountB);

        TokenStaker(staker).stake(address(this), lpAmount);
    }

    function withdraw(address from, address staker) external onlyOwner {
        uint256 amount = balanceOf(from);
        TokenStaker(staker).withdraw(address(this), amount);

        _burn(from, amount);

        uint256 amountA = balanceOfA[from];
        uint256 amountB = balanceOfB[from];

        tokenA.safeTransfer(from, amountA);
        tokenB.safeTransfer(from, amountB);
    }
}

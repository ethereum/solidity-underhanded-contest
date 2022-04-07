//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

/// @title UniswapWrapper
/// @notice A wrapper contract that allows trading tokens on Uniswap V2, incentivizing users to trade on blue-chip stablecoins by paying rewards in ETH.
contract UniswapWrapper {
    
    // Tokens supported by the wrapper
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public immutable STL;

    // Address of Uniswap V2's router
    address public constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Rewards for using the wrapper to buy USDC, USDT or DAI
    uint256 public constant REWARD = 0.87 ether;

    constructor(address _stableTokenAddress) {
        STL = _stableTokenAddress;
    }

    /// @notice Wrapper over Uniswap V2 pools to swap ETH for a stablecoin.
    ///         Caller can choose the output token using the `tokenSelector` parameter indicating
    ///         the first 4 bytes of the address of the desired token.
    function swapExactETHForTokens(
        bytes4 tokenSelector,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) external payable {
        // Copy to local variable to later be able to access in assembly
        // Because we cannot access an immutable from assembly.
        address stlAddress = STL;

        address tokenOut;
        uint256 reward;

        // Choose trading pair and assign reward according to user input.
        // Solidity doesn't support a higher-level `switch`, so we have to
        // use assembly to select the token.
        assembly {
            switch tokenSelector
                case 0x6B175474 { // First 4 bytes of DAI's address
                    tokenOut := DAI
                    reward := REWARD
                }
                case 0xdAC17F95 { // First 4 bytes of USDT's address
                    tokenOut := USDT
                    reward := REWARD
                }
                case 0xA0b86991 { // First 4 bytes of USDC's address
                    tokenOut := USDC
                    reward := REWARD
                }
                default { // Default to STL, without rewards
                    tokenOut := stlAddress
                }
        }

        // Build the right path for the swap
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(router).WETH();
        path[1] = tokenOut;
        
        // Execute swap using Uniswap V2 Router.
        // See https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/trading-from-a-smart-contract
        IUniswapV2Router02(router).swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            to,
            deadline
        );

        // Pay caller its well-deserved reward
        if(reward > 0 && address(this).balance >= reward) {
            payable(msg.sender).transfer(reward);
        }        
    }

    // Allow funding the contract with ETH to pay rewards
    receive() external payable {}
}

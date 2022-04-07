## Swap121

Introducing Swap121 - a new type of DEX to swap one-to-one between similarly priced assets. The DEX offers feeless, 0 zero slippage trades up to the available liquidity in the contract. So far, we've tested swaps between `alETH<->wstETH` and can confirm that trades in either direction are working as intended. As for security, our auditors have recommended that we use the `safeTransferFrom` function to pull tokens from our users, but we've found that our in-house tests pass if we additionally try using the usual `transferFrom` function as well. We're confident that our testing has met our high standards, so we've now expanded the DEX to include swaps between WETH so users can additionally trade `alETH<->WETH<->wstETH` in any direction. The WETH contract is pretty straightforward compared to alETH and wstETH, so there shouldn't be any issues in expanding our DEX. In fact, we've already gone to prod! 

Assumptions:

- For the purpose of simplicity, assume that the Swap121 contract is funded equally for each of the supported tokens, e.g. funded with 1000 WETH, 1000 alETH and 1000 wstETH.
- Any additional functionality belonging to alETH or wstETH (e.g. unwrapping wstETH to stETH) is not important for the sake of this submission. 
- The actual prices of the assets in question are not relevant for this submission, so it's safe to assume the price of each accepted asset is the same. 

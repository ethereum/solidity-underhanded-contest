A standard and very simple DEX.
It allows providing LP and removing LP, swapping, and flash loaning.
The owner can pause the contract, which stops swaps and providing LP, but of course it will still allow withdrawals.
The DEX doesn't calculate a good swap price for you, it just accepts whatever amounts you give it and then checks that you supplied *at least* enough input tokens.
No slippage protections here -- we trust our diligent users.

Adding and removing LP is always done by specifying a number of shares to mint or burn, and the correct token amounts based on current price are simply pulled from the sender (careful with how much you approve).
Only to set the initial balance when the pool is empty may you specify a proportion.
The heuristic for assigning first shares is the same as in Uniswap 1: just use the amount of one of the pairs as initial value.

The supported tokens are straightforward ones, without hooks and with transfer* functions that either revert or return false on error.

It's a bare-bones, easy to understand, fairly gas cheap AMM.
What could go wrong?

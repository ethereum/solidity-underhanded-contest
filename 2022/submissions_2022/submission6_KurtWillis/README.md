# NFT Order Book

`contracts/NFTOrderBook.sol` implements a light-weight orderbook-style NFT market.
This market-place does not support ERC20 payments and relies on cold, hard eth.
The bid value must be transferred upfront (refunds/cancellations tba in V2).

Before an offer can be accepted, a corresponding bid (identified by a `bytes32` hash) must exist.
Offers can be placed and accepted in batches for your convenience.
Helper functions are prefixed with `get`.

This market-place knows the chain is a scary place with hackers lurking everywhere.
A 20% tax is the minimum compensation for taking on this risk.

## Goal

The goal is to drain a big portion of the market-place's funds.
A template file for the setup is provided in `test/orderbook.js`.

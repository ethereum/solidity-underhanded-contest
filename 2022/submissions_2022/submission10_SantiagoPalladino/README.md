# ERC20 order-based exchange

Simple order-based exchange for selling ERC20 tokens in exchange for ETH. Orders are stored off-chain and signed by the sellers. Buyers submit the order to execute to the contract, along with the seller's signature and the ETH to purchase the tokens.

Orders can be `EXACT` or `PARTIAL`. Exact orders need to be fulfilled in a single operation, whereas partial orders can be fulfilled in multiple purchases from multiple buyers.

Orders can also optionally define a `referrer` address, who will receive 1% of the value in ETH of the purchase. Can be used to reward the app that stores the orders off-chain. Does not allocate a fee if set to the zero address.

## Reference

```solidity
struct Order {
  address referrer;     // optional referrer field that takes a 1% of the amount paid in ETH
  address token;        // token being offered in this order
  uint128 rate;         // number of tokens per eth sold (times RATE_DENOMINATOR)
  uint24 nonce;         // nonce for differentiating two otherwise identical orders
  uint256 amount;       // amount of tokens offered in this order
  uint8 orderType;      // type of order (EXACT=0, PARTIAL=1)
}
```

## TODO

- Allow sellers to cancel an order
- Add cross-chain replay attack protection
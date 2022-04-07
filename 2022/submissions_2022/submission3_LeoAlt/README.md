### Tests

This repo uses `forge` from Foundry.
There are a few tests written for this code, most of which are normal unit
tests, but also one that tests the rugpull.
If you do not want spoilers, **do not** open the test file.
The full spoiler is in SPOILER.md.

To run all tests run
```
$ forge test
```

### Basic Idea

The code here represents a Match Making (MM) contract that is NOT ready for
production.

The basic idea is to allow users to buy and sell from a pair of tokens T1 and
T2, by sending Sell and Buy orders at a specified price.

A sell order gives T1 and receives T2.
A buy order gives T2 and receives T1.

To simplify the contract, the price is specified as "the amount of T2 per 10^9
T1" to give some granularity without using FixedPoint libraries.
Therefore, the amount of tokens someone receives for a certain order is:
- Sell: (Quantity * Price) / 10^9
- Buy: (Quantity * 10^9) / Price

An order is only considered valid if the person would receive at least 1 of the
other token.

We keep two order arrays:
1) The Sell orders, sorted in decreasing order.
2) The Buy orders, sorted in increasing order.

A match will try to match the last element of each array, therefore the lowest
Sell and the highest Buy. For simplicity, only orders with the same price can
match.

An order may be partially filled. In this case, the desired quantity of that
order decreases by the received amount. If the updated order is invalid, it is
removed from the book.

### Known problems

Known problems and assumptions that are not part of the intended problem of
this submission:

- Since orders only match if they have the same price, even order pairs such as
  (Sell at 10, Buy at 15) would not match. We assume that someone can easily
  arbitrage this by buying at 10 from the first order and selling at 15 to the
  second.
- Someone can DoS the contract by placing many orders of the minimum amount of
  tokens that make an order valid. Conceptually this is not a problem if we
  assume gas is free (for the sake of the exercise in this submission), since
  those orders would partially match other orders and everything would still
  work, only requiring more transactions.
- Some orders may take a long time to match. If an order never matches, a user
  can simply cancel their order.

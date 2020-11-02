## Very Safu Proxy

Just a proxy that uses unstructured storage to store the following values:

  - implementation (the address of the logic contract)
  - admin (the address that has the ability to upgrade the proxy, but only if the owner allows it)
  - owner (the address that has the ability to opt-in or out of upgrades)
  - optIn (boolean representing the willingnes of the owner to having their proxy upgraded)
  
It allows the `owner` of the proxy to opt-in/out of upgrades.
It allows the `admin` to upgrade the proxy if the `owner` is willing to.

## Spoilers

It's worth saying that my original intention was to make it a fully transparent proxy, not that it would have changed the exploit,
I think it would have added to the story.

There is really no novelty to the exploit, it's a classic storage clash that 
capitalizes on the use of unstructured storage to store the proxy state.

To be specific, the storage slot where `_optIn` lives actually clashes with the `balances` mapping on an ERC20 (which I did not include)
for the address `0x47Adc0faA4f6Eb42b499187317949eD99E77EE85`, this allows `admin` to change `_optIn` to `true`
by simply sending some tokens to that account thus allowing the `admin` to upgrade the contract against the will
of the `owner` - we can easily calculate the storage slot for the balance mapping with: `keccack256(abi.encodePacked(uint256(address), uint256(slot))`
where `address` is the key for the balance mapping and `slot` is the slot in which the mapping sits on storage.

So, if there is no novelty and no excitement why submit this?

Well, to be honest I wanted to showcase how we sometimes blindly trust code that looks honest.
The proxy is filled with comments, it even gives formulas referencing eip1967 - sorry Santiago! - to how the storage slots are computed,
although out of the four only two of them are actually part of eip1967 and only 3 of them are actually true - whoops!
This means that if you are a bit lazy and you go "Oh, these 3 slots are valid so the 4th must also be valid..." or if you go like
"oh yeah EIPXXX, that must be correct" then you are basically screwed...

But lets not lose focus, what I want people to take out of this code is:

0. Do not use code that you do not understand - simply put, if you are not sure about how `delegatecall` works, do NOT use it - ask people, read articles and docs!
1. Never trust unstructured storage that does not give the formulas to how the slots are calculated!
2. Even if the formulas are given, do not trust that the coded values are the right ones!
3. Just because the comment above some random values says "EIP" do NOT trust it - specially if its not a finalized proposal.
3. Do not be lazy, verify everything !


## A little bit of context on the exploit

As we all know, when a contract (A) `delegatecalls` into another contract (B), the code in B gets 
executed in A's context. This means, amongst various things, that the storage being modified is A's.

Simply put, if we have two contracts:

```
  contract A {
    uint a;
    uint b;

    function delegateToB() {
      ...
    }
  }

  contract B {
    uint b;
    uint a;

    function foo() {
      b = b + 1;
      a = a + 2;
    }
  }
```

When A `delegatecalls` into B to execute `foo()` then `b` is going to be increased by one and
`a` is also going to be increased by two...but...that is not the whole truth - where WE (silly humans) see `a` and `b`
solidity (as the compiled language that it is) sees storage slots, to be specific from the perspective of contract A,
`a` lives at storage slot zero and `b` lives at storage slot one BUT from the perspective of contract B `a` lives at storage slot
one and `b` lives at storage slot zero which means that whenever A `delegatecalls` into B we are going to increase A's `a` by one and A's
`b` by two, which is the opposite that we are trying to achieve - oh no!

But lets not worry, as long as wee keep the same storage structure we are safe !

But to be honest having to worry about having the same storage layout in your proxy as the proxied contract is kinda annoying! So, how do we get around it?
Enter - Unstructured storage. Simply put it consists in choosing storage slots, by capitalizing on how solidity maps state variables to storage, to guarantee that the selected slots will not
clash with the proxied contract - if you do it correctly that is hehehe.

By applyimg the unstructured storage technique we can store proxy-related state without worrying about the layout of the proxied contract.

## References

[Unstructured Storage](https://blog.openzeppelin.com/upgradeability-using-unstructured-storage/)
[State of Smart Contract Upgrades](https://blog.openzeppelin.com/the-state-of-smart-contract-upgrades/)

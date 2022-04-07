# The Flaw
**TL;DR: The contract includes a [Signature Replay vulnerability](https://swcregistry.io/docs/SWC-121) that allows to bypass cancelled orders**

The flaw is actually a combination of ECDSA malleability with a wrong design choice,
in which authors decided that order IDs in the marketplace are computed as hashes
that include the signature. This means that a cancelled order can be bypassed
by providing a new order computed from the previously cancelled signature (using the
ECDSA malleability property), and that, consequently, will produce a different order ID.

Note that although the facts that ECDSA is malleable and the `ecrecover` precompile doesn't seem to care
are well-known, it's still common to find implementations in the wild that don't check for this (even if there are great libraries that do the job, like [OpenZeppelin's ECDSA contract](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol)).

As an example, [OpenSea's Wyvern v1](https://etherscan.io/address/0x7be8076f4ea4a4ad08075c2508e481d6c946d12b#code), which was the logic running the OpenSea marketplace until roughly a month ago, didn't check for malleable signatures (see L682 in [their code](https://etherscan.io/address/0x7be8076f4ea4a4ad08075c2508e481d6c946d12b#code)). 
OpenSea was exploited using signatures very recently, which probably motivated the recent upgrade to OpenSea's Wyvern v2.3,
where the fix for malleable signatures is at last included. Nevertheless, it's a bit worrying that this problem was present just one month ago (although it doesn't seem it was exploitable). 

This submission shows that a seemingly innocent design choice (i.e. using the signature as part of the ID for something), together with a naive use of a native EVM primitive like the `ecrecover` precompile, can have disastrous consequences for users of the contract.

# References
- Missing Protection against Signature Replay Attacks - https://swcregistry.io/docs/SWC-121
- OpenSea's Wyvern v1 - https://etherscan.io/address/0x7be8076f4ea4a4ad08075c2508e481d6c946d12b#code
- OpenZeppelin's ECDSA contract - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol

# InstantVoting: Streamlined On-Chain Governance

_Submission for the 2024 [Underhanded Solidity Contest](https://underhanded.soliditylang.org/)._

## Overview

`InstantVoting` is an innovative smart contract designed to simplify and accelerate the governance process for DAOs. By leveraging transient storage and efficient vote collection, `InstantVoting` offers a more responsive and gas-efficient alternative to traditional governance mechanisms.

> [!IMPORTANT]
> 
> **SPOILER ALERT:** Explanation and proof-of-concept can be found in `test/exploit.t.sol`.

Running the tests:
```
foundryup
forge soldeer install
forge test
```

## Key Features

1. **Asynchronous Voting**: Voters can cast their votes at any time before the vote collection occurs, allowing for flexible participation.
2. **Instant Vote Collection**: Votes are collected and tallied in a single transaction, eliminating the need for lengthy voting periods.
3. **Flexible Voter Registry**: Supports multiple voter registries, allowing for dynamic and adaptable voting populations.
4. **Immediate Execution**: Proposals can be executed in the same transaction as vote tallying, significantly reducing the time from proposal to action.
5. **Gas Optimization**: Employs transient storage to minimize gas costs associated with vote collection and tallying.

Experience the future of DAO governance with `InstantVoting` - where decisions happen at the speed of your transactions, without sacrificing voter flexibility!

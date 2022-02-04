# Solidity Underhanded 2020

## Upgradable Libraries

Solidity libraries can be linked at deploy time to minimize a contract's footprint. The idea is to reuse particularly expensive code and save on gas, but if a flaw is found, all downstream consumers are affected. It therefore makes sense to consider how these may be upgraded.

When considering upgradeable contracts we are likely to adopt the proxy model. This allows the contract authority to upgrade the core logic while retaining the base contract address. It accomplishes this by delegating all unknown calls through the fallback function by forwarding the message payload.

The upgrade mechanism contained therein utilizes a typical proxy to forward library calls, but since the proxy itself is delegated to we cannot store the implementation address. The solution is to utilize another getter / setter contract for which we can hardcode the address. This allows the authority to easily upgrade the library by updating the address which is pointed to.

In practice it is more common to upgrade the contract which references a library since we would not expect our dependencies to suddenly change under-the-hood. Looking at the code alone, there is also nothing to indicate that a proxy may be used in-place of a library as the interface is inherited directly.

## Getting Started

The contracts and libraries are defined solely in `./contracts/Accounts.sol`, with some tests in `./test/upgrade.test.ts`. Users are expected to interact with the `Accounts` contract which is basically a dumb ERC-20 contract. This utilizes the `GoodMath` library for all arithmetic, but the deployer has actually linked a proxy address. This means that the authority may instead forward calls to the `BadMath` library which reverses the expected mathematical operations.

```shell
# install buidler and deps
yarn install
# compile contracts, typescript interfaces
yarn build
# run tests
yarn test
```


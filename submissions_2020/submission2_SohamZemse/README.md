# Give Away :: Solidity Underhand Submission

This is a submission for [Solidity Underhand Contest](https://underhanded.soliditylang.org/).

## Brief

This is a smart contract honey pot based on **proxy**. A random user on the internet visits the contract address on Etherscan with verified source code, that has nice ether in it. The user notices that there is a method that helps anyone to take control of the contract by upgrading the implementation containing a method that allows only them to withdraw the entire balance of the contract.

## About Files Included

- GiveAway_v1.sol (the main_v1 file)
- GiveAway_v2.sol (the main_v2 file)
- Proxiable.sol (standard file, taken from [ERC1822](https://github.com/ethereum/EIPs/blob/62f5f2105e41c5a2c6a1a8d0e5c642107eaec0ce/EIPS/eip-1822.md#constructor), inherited in main files)
- Proxy.sol (standard file, taken from [ERC1822](https://github.com/ethereum/EIPs/blob/62f5f2105e41c5a2c6a1a8d0e5c642107eaec0ce/EIPS/eip-1822.md#proxiable-contract), the proxy file)
- README

## How it should work

1. Person A deploys `GiveAway_v1.sol` at `0xGiveAwayV1`.
2. Person A deploys `Proxy.sol` at `0xProxy` with args `0x` and `0xGiveAway`.
3. Person A sends `initialize()` tx to `0xProxy` with value `10 ether`.
4. Person B sees this, and notices that there could be a `getGift()` method in the implementation.
5. Person B deploys `GiveAway_v2.sol` at `0xGiveAwayV2`, that has the method `withdraw2()` with their address and `withdraw()` method commented so that the original owner should not be able to withdraw.
6. Person B calls `updateCodeAddress(address)` on `0xProxy`, passing `0xGiveAwayV2` as arg and sending in the minimum `1 ether + 1` value.
7. Person B calls `withdraw2()` and gets `11 ether + 1`.

<!-- The second and third step could be squashed, into the `constructorData` as `0x8129fc1c` (`initialize()`), but since it's payable, the require statement in `initialize` method fails. -->

## How it works / Spoilers

Those who are familiar with how smart contract proxies work, they might have already catched the flaw. The existance of the flaw results the deployer having full control, even if it does not seem like it. So here it is! When we deployed the implementation contract, we had the constructor set the value of `available` storage var. A proxied contract [cannot have a constructor](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/e5fbbda9bac49039847a7ed20c1d966766ecc64a/contracts/proxy/Initializable.sol#L9), so the `available` storage var is not initialized in the proxy contract. The users who are not aware of this might think they can get the control of contract. In the step 6, the `if` condition in `updateCodeAddress` method is not satisfied due to nullish value in `available`, which doesn't actually update the implementation address as it seems.

## Considerations

The scamy theme is choosen as a parody for so many scams online. Goal of this, is to bring awareness about such acts happening online which defames a good technology.

## Acknowledgements

Thanks to organisers for the initiative!

## License

MIT

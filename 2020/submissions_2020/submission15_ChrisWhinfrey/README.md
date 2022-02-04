# VampireSwap

![DefiVlad](images/DefiVlad.png)
Vlad is the pseudonymous founder of the hyped new DeFi project, VampireSwap.

### The Set Up

Vlad has just announced that top auditing firm Open Trail of Diligence has completed their audit and the upgradable token contract has been deployed and verified on Etherscan.

Proxy - The upgradable proxy
https://goerli.etherscan.io/address/0x57FC492706eA4229866D2d5E2e5538f7a50bD154#code

Token - The implementation
https://goerli.etherscan.io/address/0x294fE50c6e86C799157E18418748B4782eccFbC1#code

Later, [Not shown] Vlad deploys the rest of the VampireSwap contracts that are also upgradeable and are controlled by the same governance contract as the token.

### The Attack 🦇

Total value locked in VampireSwap skyrockets as it sucks the liquidity from its competitors. But the next morning everything is gone...

Vlad has accessed an enormous token balance which wasn't accounted for in any of the events or the token's `totalBalance`. The large token balance
allowed Vlad to take control of the governance contract, upgrade every VampireSwap contract and take not only all of the funds in the contracts but also drain 🧛 the accounts of users that approved unlimited tokens to the VampireSwap contracts.

_Hint: Vlad's secret address is `0x4ea63D4a3727b38Cd3a9F5B64b9CC1C6822bf6A9`. Check it's balance by calling `balanceOf` on the upgradable proxy._

Can you figure out how he did it?

_Note: The Governance contract is not implemented. Both the Governance contract and the Token contract can be assumed to be fully functional and secure._

## Spoilers

Vlad was able to silently add tokens to his account during the call to `initializeProxy` on the `Proxy`. He did this by initializing the proxy with a malicious implementation (`contracts/spoilers/Backdoor.sol`). When the proxy calls `Initializable(address(this)).initialize(_admin)`, the backdoor silently mints the extra tokens and then sets the implementation slot to the `Token` contract to avoid detection.

The `ImplementationChanged` event is then emitted showing a change from `address(0)` to the `Token` contract leaving no trace that `Backdoor` was ever set as an implementation at all.

### Why this attack is dangerous

Unless you manually verified the inputs of the `initializeProxy` call, this attack is virtually undetectable. Because storage is altered directly in the `Backdoor`'s, initializer, no events are emitted that would give it away. Additionally, it's unlikely the abnormally large balance would be detected because it must be looked up by Vlad's address which is secret until the attack starts.
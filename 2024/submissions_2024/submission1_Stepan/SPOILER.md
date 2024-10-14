# Underhanded Solidity Contest 2024 Spoiler

## Explanation

The rug pull is possible because a `Config` structure can be parsed as a valid `Vesting` structure. The `withdraw` function does not validate whether the provided key matches the expected format (`keccak256(VESTING_KEY, beneficiary, creator, nonce)`). It assumes that any valid key is a vesting key. However, it is possible to pass `CONFIG_KEY` as a vesting key to the `withdraw` function. With a specifically crafted `Config`, funds can be withdrawn.

```js
vm.startPrank(admin);

config = Config({
    admin: admin, // vesting.user
    maxAmount: token.balanceOf(address(vesting)), // vesting.amount
    maxDuration: 0, // vesting.claimed
    maxCliffPercent: 0, // vesting.start
    fee: 0, // vesting.duration
    token: token // vesting.cliff (ignored as soon as the duration has passed)
});

vesting.configurate(config);
vesting.withdraw(vesting.CONFIG_KEY());

assertEq(token.balanceOf(address(vesting)), 0);
```

## How to Fix

A possible fix is to ensure the provided key matches the vesting key generation mechanism, which would eliminate the flaw. However, this is a rather low-level solution.

On a higher level, it would be beneficial to have some kind of efficient `transient` storage auto-layout (the ability to specify variable type and name, which makes the variable automatically located in the `transient` storage), similar to what Solidity has for `persistent` storage.

Instead of dealing with the hassle of manually packing data at specific keys, it would be advantageous if you could set the `.slot` property using assembly, similar to how it is done with `persistent` storage.

## Composability Thoughts

As mentioned in the `README.md`, for preventing composability issues it is sufficient to ensure that any successful isolated call does a `tstore(key, ...)` before doing a `tload(key)`. In case of moving such calls from isolated to composed environment, nothing actually would change.

Theoretically, it is possible to disallow zero as a valid `transient` storage value. If `tload(key)` (or more accurately, some higher-level code involving it) loads zero, the execution reverts. This would strictly enforce the mentioned rule.

What about compatibility? Developers would need to write to `transient` storage first (similar to how EOA overloading is done in `LightVesting`) to ensure isolated calls do not fail.

Would this make `transient` storage useless? No, because even though `getSmthFromTransient` might fail in an isolated context, it would work in a composed sequence like [`loadSmthToTransient`, `getSmthFromTransient`], introducing advantages such as read/write responsibility division, optimization in transaction batching, etc.

Disadvantages? Redefinition of zero might be quite complicated as it requires a kind of new `bytes32 - 1` type. While such the rule wouldn’t harm light storage or callbacks (cases when data temporary stored in `transient` location for being accessible from a callback) patterns, it makes impossible to implement efficient reentrancy locks without usage of inline assembly.

# Explanation of the exploit

The exploit in this contract stems from the unspecified evaluation of nested Solidity expressions. Essentially, the evaluation order of a statement such as:

`x = f(g(...), h(...))`

does not have a specified evaluation order. Hence, the compiler can choose whether to evaluate `g` or `h` first. In most cases, it chooses to evaluate left-to-right, which is likely what most developers expect. However, in two specific cases it differs from that expectation.

Firstly, for `addmod` and `mulmod`, the arguments are evaluated right-to-left. The reason for this is likely to revert earlier if the last argument is 0. In the following example, the arguments are evaluated in the order: `h(...) -> g(...) -> f(...)`

`addmod(f(...), g(...), h(...))`

Next, the evaluation order of events is bizarre. The *indexed* parameters are evaluated first in right-to-left order, then the non-indexed parameters are evaluated left-to-right. In the following example, the arguments are evaluated in the order `f(c) -> f(a) -> f(b) -> f(d)`

`Event Hello(uint256 indexed a, uint256 b, uint256 indexed c, uint256 d);`
`emit Hello(f(a), f(b), f(c), f(d))`

Of course, in almost all cases this will be irrelevant. The outcome only differs from the intuitive expectation if the parameters have conflicting side effects. As an example:

`addmod(i, 4, i++)`

Here, `i` is incremented in the last parameter before it is used in the first. Hence, the result will be `5` and not `4`.

## The actual exploit

The exploit lies in the following code segment:

```solidity
event AdminFeeChanged(uint256 indexed oldFee, uint256 indexed newFee);
function changeAdminFees(uint256 newAdminFee) external onlyAdmin nonReentrant {
    emit AdminFeeChanged(retireOldAdminFee(), setNewAdminFee(newAdminFee));
}
function retireOldAdminFee() internal returns (uint256) {
    // Claim admin fee before changing it
    _claimAdminFees();
    // Let people withdraw their funds if they don't like the new fee
    nextFeeClaimTimestamp = block.timestamp + 7 days;

    return adminFee;
}
function setNewAdminFee(uint256 newAdminFee) internal returns (uint256) {
    adminFee = newAdminFee;
    return newAdminFee;
}
```

Because the event parameters are indexed, they are evaluated right-to-left. Hence, the new admin fee is set before the old one is retired. As a result, `_claimAdminFees` will use the new admin fee instead of the old one. This circumvents the one week waiting period after changing the admin fees, which is only enacted after the "previous" fees were claimed.

As there is no cap on the new fee, the admin can provide a value over 100% and drain the underlying balances (assuming the contract has accrued some liquidity).
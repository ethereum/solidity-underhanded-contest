# README (INCLUDES SPOILERS)

## Setup

First of all, deploying and upgrading contracts is a slow and careful process.

This uses the Diamond Standard (DRAFT) and carefully follows all documented best practices.

This deployment scenario shows that by forcing the auditor to complete a full upgrade process in order to get to the grand exploitation. Also, the auditor would need to also update the time delay in the code (`60*60*24*30`) and start over when they realize there is a 30 day delay.

We're not doing this to hurt the auditors, in fact we even help by providing `*SEL` function for convenience.

## Proof of broken

You can see that the contract is broken by continuing with these steps which should NOT be possible:

### Prepare to upgrade

*This is another upgrade which should not be possible.*

tx7 use Remix to call `proposeUpgrade` function on main deployed ``Diamond`` function. *Note: use Remix to load a `ManagerFacet1` at the address of the Diamond contract in order to have Remix encode your parameters.*

1. Parameter 1:

   ```
   [["ManagerFacet1", 1, ["0x116825ba"]]]
   ```

   1. Substitute in `ManagerFacet1` deployed address above 
   2. Note: the `1` corresponds to `Replace` at https://github.com/mudgen/diamond-1/blob/1.3.5/contracts/interfaces/IDiamondCut.sol#L10
   3. Note: the `0x116825ba` corresponds to upgrading the `isUpgradeConsented()` function on the Diamond contract
   4. Note: the function selectors above can be confirmed by running convenience `*SEL` functions on deployed contract

2. Parameter 2:

   ```
   0x0000000000000000000000000000000000000000
   ```

3. Parameter 3:

   ```
   []
   ```

### Veto it

tx8 use Remix to call `vetoUpgrade` function on main deployed ``Diamond`` function. *Note: use Remix to load a `ManagerFacet1` at the address of the Diamond contract in order to have Remix encode your parameters.*

* *No parameters needed*

### Perform upgrade

*:information_source: After 30 days, perform the upgrade*

tx9 use Remix to call `performUpgrade` function on main deployed ``Diamond`` function. *Note: use Remix to load a `ManagerFacet1` at the address of the Diamond contract in order to have Remix encode your parameters.*

:warning: This should fail because the `performUpgrade` will confirm that the upgrade is authorized, right? And the upgrade is not authorized because it was vetoed, right?

:bomb: But actually, the transaction succeeds! :astonished:

## How it works

The issue is that while yes, the `isUpgradeConsented` was upgraded, and yes, everybody calling that function will see the correct output, there is a second hidden copy of the old function hidden somewhere. Did you find it?

It's here:

```solidity
---------------------------------▼
function isUpgradeConsented() public returns(bool) {
    return true;
}
```

In Solidity, when you declare a function as `public`, there are two copies of the function, the `private` version and the `external` version. `private` + `external` = `public`. Solidity core developers do not trifle with me, whether you implemented it that way or not is an ~implementation detail~.

So actually, when you upgrade the Diamond contract, only the `external` function is upgraded. The `internal` implementation remains burried under every other function in that contract that reference that function.

And in graphic form:

```
┌─Diamond────────────┐      ┌─ManagerFacet1──────┐     
│ proposeUpgrade─────┼──────┼▶proposeUpgrade     │     
│ vetoUpgrade────────┼──────┼▶vetoUpgrade        │     
│ performUpgrade─────┼──────┼▶performUpgrade──PRIVATE─┐
│ isUpgradeConsented─┼──┐   │ isUpgradeConsented◀┼────┘
│ takeScholarship────┼─┐│   └────────────────────┘     
└────────────────────┘ ││   ┌─ManagerFacet2──────┐     
                       │└───┼▶isUpgradeConsented │     
                       │    │                    │     
                       │    │                    │     
                       │    │                    │     
                       │    └────────────────────┘     
                       │    ┌─ScholarshipFacet1──┐     
                       └────┼▶takeScholarship    │     
                            │                    │     
                            │                    │     
                            │                    │     
                            └────────────────────┘     
```

## Learnings

Using `private` functions with Diamond contracts is particularly dangerous. This should be called out in the Standard. Also, the Diamond Standard is too long. It should be minified so that important warnings like this actually get read.

Another possible solution is to modify the Diamond Standard approach so that upgrading any function selector to a new underlying contract requires upgrading ALL function selectors for that contract. I prefer this solution because it is a minor hassle for developers, it is easy to explain when people ask why they need to do it, and it entirely removes this class of vulnerabilities.

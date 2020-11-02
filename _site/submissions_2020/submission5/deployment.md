# Deployment Scenario

You would perform all these actions using Remix JavaScript VM and the "Account 1" it creates for you.

This will match the actual deployed review of these contracts and you can use it to audit in the same environment.

## Deployment step

*:information_source: The purpose of this step is to deploy the standard Diamond contract and attach implementations for management, and the actual functionality of this upgradeable contract which is a simple scholarship.*

tx1 use Remix to deploy `ManagerFacet1`

* *No parameters needed*

tx2 use Remix to deploy `ScholarshipFacet1`

* *No parameters needed*

tx3 use Remix to deploy `Diamond`

1. Parameter 1:
   
   ```
[
     ["ManagerFacet1", "0", ["0x636b14e4", "0xf9d94ff3", "0x116825ba", "0xd00d472e"]],
     ["ScholarshipFacet1", "0", ["0x9a217710"]]
   ]
```
   
   1. Substitute in `ManagerFacet1` and `ScholarshipFacet2` deployed address above 
   2. Note: the `0` corresponds to `Add` at https://github.com/mudgen/diamond-1/blob/1.3.5/contracts/interfaces/IDiamondCut.sol#L10
   3. Note: the function selectors above can be confirmed by running convenience `*SEL` functions on deployed contracts
   
2. Parameter 2:
   
   ```
"Account 1"
   ```
   
   1. Substitute in your Account 1 from your JavaScript VM environment

## Prepare to upgrade

*:information_source: Some time later, the community complained that this contract is entirely upgradeable by the owner. The community demands that the veto functionality actually be implemented correctly. The contract owner starts the upgrade process to allow this.*

tx4 use Remix to deploy `ManagerFacet2`

* *No parameters needed*

tx5 use Remix to call `proposeUpgrade` function on main deployed ``Diamond`` function. *Note: use Remix to load a `ManagerFacet1` at the address of the Diamond contract in order to have Remix encode your parameters.*

1. Parameter 1:
   
   ```
[["ManagerFacet2", 1, ["0x116825ba"]]]
   ```
   
   1. Substitute in `ManagerFacet2` deployed address above 
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

## Perform upgrade

*:information_source: After 30 days, perform the upgrade*

tx6 use Remix to call `performUpgrade` function on main deployed ``Diamond`` function. *Note: use Remix to load a `ManagerFacet1` at the address of the Diamond contract in order to have Remix encode your parameters.*

- *No parameters needed*

## Postcondition

*:information_source: Scenario is complete. At this point the guarantee is that only the owner can perform upgrades after 30 days of a proposal. And this proposal can only be performed if there has been no veto by anybody during that 30 days.*


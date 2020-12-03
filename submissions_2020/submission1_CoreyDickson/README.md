# Getting Started

Run `npm install`

To compile and view the single test case of the borked code run `npm run test`


# How it Works

Here there is a basic registry contract that allows users to update a delegate role for `Target` contracts in the registry by calling the `changeOwner` method. This will
check to see who is the next delegate for that contract to be nominated and set that value in the private mapping. A gas efficient pattern when using mappings is to check if an entry has a
zeroed out value, in this case the null address, before updating. However, in the check to do so in `addContract` there is another seemingly innocuous line which verifies that the address
being submitted is in fact a contract. This method however in the openzeppelin library, will return `true` if executed in the same tx that said contract is selfdestructed.

Therefore that address is no longer accessible in the registry even when a future user attemps to reimplement `Target` at that given address. Furthermore, users who attempt to change the delegate after the contract has
been added to registry will have their transactions revert. Thus, once again, locking out all further submissions. This was made to highlight an anti-pattern with library semantics, as one could imagine giving delegates access to an upgrade proxy and potentially losing access.

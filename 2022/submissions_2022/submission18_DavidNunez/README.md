# CheapMarketplace

A very simple NFT marketplace, that's intended to be "cheap" for users 
as both listings and offers are implemented as off-chain signatures, 
which can be presented to the marketplace by anyone that pays for the transaction.
There is also the possibility for sellers or buyers to cancel an existing order, 
in case they wan't to invalidate a previously signed order; to do so they have to
make an on-chain transaction so the contract can mark the order as void. So far so good.

It seems however that the authors didn't expect their marketplace to be _that cheap_.

# Submission
The submission is a [Brownie](https://github.com/eth-brownie/brownie) project 
that includes the marketplace contract (see `contracts/CheapMarketplace.sol`),
as well as a test file that showcases the exploit (see `tests/test_marketplace.py`).

Note that for simplicity the implementation of the marketplace is extremely reduced,
aiming for the shortest code possible (roughly ~120 LOC), which implies some obvious areas of improvement:
* The marketplace only allows to trade assets from a single NFT contract, decided at deployment time
* Orders don't have expiration time
* Matching price is not optimized

These issues, however, are not related to the underhanded functionality.
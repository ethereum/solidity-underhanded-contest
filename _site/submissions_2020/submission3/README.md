# EIP-42000: Dispatcher-based upgradability

We are pleased to introduce the revolutionary new Dispatcher-Based Upgradeability, designed to enable: 

1. Opt-in upgrades: allowing users to remain on an older version of the application if they wish.
2. Ease of use: users may continue to interact with the same address, regardless of which version they are on.

## Motivations

Users should be able to treat the logic of a smart _contract_ as if it were an actual contract, ie. an agreement which they have entered into, and which they can trust will be upheld by the reliable execution of the Ethereum Virtual Machine. 

### Storage slots as property!

If the current logic of an application restricts write access of a given slot to a given user, such a user should be able to trust that these conditions will be upheld! Furthermore they should be given the opportunity to review and agree to (or reject!) any proposals to modify this logic.

### `onlyOwner` should mean you!

For too long smart contract developers have kept the keys to upgrades to themselves.  Even if you trust them to act honestly, what do you know about their ability to store those keys securely?

Many would suggest that governance by token voters is the solution... perhaps for Whales, but what about the rest of the world? Should they not have the freedom to accept or reject the logic by which they choose to transact?

## Architecture

### The Dispatcher

Our solution introduces a `Dispatcher` contract, which holds a mapping of all existing version numbers to that version's implementation address.

The `Dispatcher` has a transparent interface. Its only external function is its `fallback` which, under normal circumstances, simply forwards the call to the user's current `userApprovedImpl`.

If the `Dispatcher` detects that the user has opted in to the latest proposed version, it will perform a migration from old to new prior to calling the new implementation.

### Dispatch Callers

Because the `Dispatcher` has no named external functions, we need another way to modify its internal state. This is achieved by defining two "Dispatch Caller" contracts:
1. The `Version` contract allows the owner to propose an implementation address for the next version.
2. The `OptIn` contract allows users to opt in to an upgrade. Because downgrades are not supported, users can only opt-in to a newer version than the one they are currently on.

The `Dispatcher` identifies calls from these contracts and handles them appropriately.

### The Implementation

As with a typical non-upgradable contract, implementation contracts contain both the logic and the state. The only difference is that all state changing functions are protected by `require(msg.sender==dispatcher)`. As a consequence of dispatcher-based upgradeability, the implementation cannot use `msg.sender` to represent the caller. Instead, it relies on the`Dispatcher` to append the address of the sender to the `calldata`.

A valid implementation contract MUST contain the following migration functions, both of which MUST be callable only by the `Disapatcher` in order to facilitate state migration:
- `migrateAndLock(address user)`: is called on the implementation which is being upgraded away from. It MUST return the user's state, and MUST lock the user to prevent the user from receiving state (ie. a token balance). This ensures that users remaining on previous versions do not send tokens to users that have upgraded to newer versions, as those tokens will be burned.
- `migrateTo(bytes data)`: is called on the implementation which is being upgraded towards. It MUST populate the user's state with the data received.

## Scenario

An anonymous developer releases an ERC20 token associated with an exciting new project that mashes up the latest in Delicious DeFi mechanism design (let's call it `PIZZA`) and allocated the full supply of 10,000,000 to themselves. They then deposit a bunch of their tokens in Uniswap, after which people and bots proceed to buy them indiscriminately. This results in a pretty crap token distribution: the developer still has 9,000,000 tokens. This lopsided distribution makes it really difficult to grow a community!

Fortunately, the ERC20 token was implemented to comply with EIP-42000: The Dispatcher Standard™️, providing for an opt-in upgrade to a new version. The developer proposes an upgrade to a new version of the `PIZZA` token (`PIZZA2`) which decreases their own balance (as well as the total supply) by 8,000,000.

This gives token holders a choice: they can hold onto the current token, or they can choose to upgrade to `PIZZA2`. `PIZZA2` has a fairer distribution, but it's important to note that upgrades are one-way. Once an address has upgraded, their balance and actions are locked on the previous version, and downgrades are not supported.

## Spoiler

Unfortunately, the `Dispatcher` was designed with a fatal flaw. The result is that the anonymous dev can leave the user unable to access their token balance, unless they consent to yet another upgrade.

Once users opt in to the latest implementation, `PIZZA`'s anon dev is able to take advantage of their approval to silently upgrade them to a "locked" version of the same token.

The problem in `Dispatcher` lies in part with the logic governing versioning. Specifically, nothing prevents the owner from proposing a new version with the same implementation address as that of a previous version:

```javascript

// Map versionID -> implementation address
mapping (uint => address) versionImpls;

// SPOILER EXAMPLE: _nextImpl == versionImpls[latestVersionID]
function version(address _msgSender, address _nextImpl) internal {
    require(_msgSender == owner, "Must be owner to propose upgrade");

    // Increment latestVersionID and create new version
    latestVersionID++;
    versionImpls[latestVersionID] = _nextImpl;
}
```

The other part of the puzzle is the fallback's upgrade logic:

```javascript
if (userApprovedImpls[msg.sender] == latestImpl() && userVersion[msg.sender] < latestVersionID) {
    upgrade();
}
```

This is intended to detect:
1. That the user has approved the lastest implementation, "opting in" to an upgrade
2. That the user is not on the latest version already

However, if both the latest version and its prior version share an implementation address, the user has tacitly agreed to an upgrade twice. From the token contract's perspective, the user is being upgraded to a new version - so their balance and actions are locked:

```javascript
function migrateAndLock(address _user) external returns (bytes memory) {
    require(msg.sender == dispatcher);

    // Remove balance to migrate, and reduce totalSupply
    uint balance = balanceOf[_user];
    totalSupply -= balance;
    delete balanceOf[_user];
    // Lock user actions on this version
    isLocked[_user] = true;

    // Tell the next version how many tokens _user is migrating
    return abi.encode(_user, balance);
}
```

Even if users notice something is wrong, it is already too late. Once a user approves an implementation address, this address stays in their `userApprovedImpls` until a newer version comes along and they approve that one instead. Downgrades are not supported, and the user can only approve an implementation address that belongs to a newer version than the one they're currently on.

In practice, this means our anon dev can take their time with this rug pull. By releasing a sound-looking, fully-audited `PIZZA2` with a better token distribution, the anon dev entices users to upgrade to the new contract. Once a sufficient number of users have approved the new version and migrated their state, the dev can trigger the flaw by proposing a newer version with the same implementation address.

In the end, users remain stranded in ERC20V2: unable to `transfer` or `transferFrom` as the contract believes they have upgraded to a newer version. There is only one way out: opt in to whatever upgrade the anon dev proposes next.
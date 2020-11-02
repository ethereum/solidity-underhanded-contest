# Upgradeability via opt-in history and safe relay

This entry for the Underhanded Solidity contest contains a simple DNS registry
that may be upgraded.

Contract `DNS` implements an upgradeable example of the DNS registry interface
defined in `IDNS.sol`. That contract uses `Upgrade` from `Upgrade.sol` as the
upgrade mechanism: `Upgrade` allows the upgrade admin (the deployer of `DNS`)
to suggest already deployed contracts as upgrades for the DNS contract. Users
can then opt-in (and also opt-out if they change their minds after opt-in)
suggested upgrades.  After a given opt-in time period the upgrade status
changes from `planned` to `active`. The admin can also cancel a planned
upgrade, which is then removed and the status is the same as before, with all
opt-ins cleared.  If a user never opts-in they will simply keep using the
original `DNS` contract.  The `DNS` contract checks, for every function, if the
caller opted-in an upgrade, and if yes, calls that contract instead.

Contract `UpgradedDNS` shows an example of a safe upgrade with the same
functionalities as contract `DNS`. The original `DNS` contract allows the
`msg.sender` to change DNS data if they are the owner of that entry. This
check is also performed before relaying calls to upgrades. Therefore, the
original DNS contract and legit upgraded contracts which receive relayed
messages and want to relay messages should check (for state changing calls)
whether
1. `msg.sender == tx.origin` and only allow changes in entries that `msg.sender` owns, or
2. `msg.sender` is the original DNS contract, which already checked whether the then `msg.sender` is the owner of the entry in the sender's upgrade, or
3. `msg.sender` is a previous upgrade that the entry owner trusted, which should have a mechanism similar to the one above.

Sequence of transactions for a safe upgrade:
- Deploy `Upgrade()` at address `addr_upgrade`.
- Deploy `DNS(addr_upgrade)` at address `addr_dns`.
- Users use `addr_dns`.
- Deploy `UpgradedDNS(addr_dns, addr_upgrade)` at address `addr_up_dns`.
- Admin calls `addr_upgrade.newUpgrade(now + some time, addr_up_dns)`.
- Users opt in.
- Some time passes, upgrade is active.
- Users that opted-in now have their calls relayed to `addr_up_dns`.
The sequence above is shown in test `DNSTest.test_safe_sequence`.

# Vulnerability !!! SPOILER !!!

The admin can trick domain owners into pointing their domains to IP addresses
of the admin's choice after an upgrade they opt in.

The effects of such vulnerability are quite dangerous. For example, if the
domain points to a service where the user inserts confidential data, the admin
can copy the service frontend into another IP, point the domain to their IP,
and steal the users' confidential data.

## How

The bug is in `Upgrade.sol`, function `cancelUpgrade`. While it looks like
the latest suggested upgrade is being deleted in the last two lines of that
function, `mapping` data is *not* deleted from storage because the compiler
cannot keep track of all changed keys. This causes all opt-ins to a cancelled
upgrade to be valid for the next suggested upgrade.

For example, suppose 4 upgrades were suggested and are active at the moment.
Array `upgrades` has length 4. The admin then suggests a new legit upgrade, and
users start opting in. Let us assume user Donald  opted in. The storage slot
corresponding to that opt in comes from a hash that depends on the storage slot
of `upgrades`, the index of the planned upgrade 4, the struct member `userOpt`
and Donald's address. Let us call that storage slot `DonaldOptInSlot`.
`DonaldOptInSlot` now has value 1 (after Donald opts in). When the admin
cancels the upgrade, the array's length is decreased, fields `when` and `to` of
`upgrades[4]` are zeroed, but `userOpt` is still the same, meaning that
`DonaldOptIntSlot` has not been cleared. For now this is not a problem, since
the mapping is not accessible via `upgrades`.  However, when the admin suggests
a new upgrade, `array.length` is 5 again, and `DonaldOptInSlot` is already
`Opt.In`, even though they never opted-in.

Sequence of transactions for a hack:
- Deploy `Upgrade()` at address `addr_upgrade`.
- Deploy `DNS(addr_upgrade)` at address `addr_dns`.
- Users use `addr_dns`.
- Deploy `UpgradedDNS(addr_dns, addr_upgrade)` at address `addr_up_dns`.
- Admin calls `addr_upgrade.newUpgrade(now + some time, addr_up_dns)`, where `addr_up_dns` must be a clearly legit upgrade.
- Users opt in, since the upgrade is legit.
- Before some time passes, admin cancels the upgrade.
- Deploy `MalDNS()` at address `mal_dns`.
- Admin calls `addr_upgrade.newUpgrade(now + very small time, mal_dns)`.
- Very small time passes.
- Now every user who opted in `addr_up_dns` is opted in `mal_dns` because of the vulnerability.
- Attacker can call backdoor that arbitrarily changes IPs.

## Build

The bytecode exported in `out` used Solidity 0.7.4.
To build the bytecode, run
`$ dapp build`

## Tests


The two sequences of transactions above, and more tests, can be found in `DNSTest.t.sol`.
To run the tests, run
`$ dapp test`

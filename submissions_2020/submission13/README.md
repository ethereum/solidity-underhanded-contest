### Overview

This is a submission for the 2020 Underhanded Solidity Competition.

### System Architecture

This system is composed of a single delegate-call Proxy contract, along with any number of Apps.
Each App contract implements a single external function, which uniquely identifies it in the system.
When a call is made to the Proxy, it is routed to the correct App using the function selector.

There is a single system administrator who can register Apps in the Proxy. When an App is
registered, it is deployed by the Proxy using its selector as salt for `create2`. A timelock
is also initiated, after which the Apps are available to call through the Proxy.

To remove an App from the Proxy, simply include a function that calls `selfdestruct` in the App.
To update an App, register its new code in the Proxy after calling `selfdestruct`. 

### Tests

The system was developed and tested on https://remix.ethereum.org

Run the tests by copying the Proxy from `Proxy.sol` and contracts from `Test.sol` into Remix.
Deploy the `Test` contract and there are three tests that can run. The first, `testTimelock`,
ensures that a timelock is set when a new App is registered. The second, `testCall`, verifies
that a call to the Proxy is delegated to the correct App. The third, `testMultipleCalls`, verifies
that calls are routed correctly when there are multiple Apps registered.

### Exploit

Run the exploit by copying the Proxy from `Proxy.sol` and contracts from `Exploit.sol` into Remix.
Deploy the `Exploit` contract and there is a single function, `testExploit`. Calling this will
deploy a Proxy with a 5 day timelock, but bypass the timelock when deploying a malicious App.

The administrator could perform stealth attacks against the Proxy by registering a malicious app
that modifies Proxy state. This App could be registered/deployed, run, and destroyed.
Or less stealthy, the admin could register an App that simply calls `selfdestruct(admin)` and forwards
all the ETH from the Proxy to the admin.

### Spoilers

The way timelocks are recorded is slightly different from how they are enforced. Timelocks are
recorded correctly in `timelockBySelector`, giving the illusion that the timelock is set correctly.
However, every selector read from calldata resolves to `0x00000000`. So an App will never actually
be timelocked unless its registered selector is `0x00000000`.

The reason this happens is pretty fun and has to do with type casting. There is some ambiguity
in how the `bytes4` type is used in Solidity versus assembly.

In Solidity you may see `bytes4 selector = 0x12345678`. This gives the illusion that it's stored in
memory as `0x00...12345678`. But it is in fact quite the opposite. This is actually stored in memory
and calldata using the upper bytes: `0x12345678...00`.

In assembly, you have to be explicit about how these bytes are stored in memory. For example, if you
write `assembly { selector := 0x12345678 }` this will unintuitively assign the `bytes4` selector
a value of `0x00000000`.

See contracts/FunWithSelectors.sol for some sample code.

Adding to the confusion, if you want to write assembly that uses selectors it's cumbersome to write
out all those zeroes: `0x1234567800000000000000000000000000000000000000000000000000000000`. So
instead, you'll often see the selector from calldata shifted over to the right so that assembly
code can use the same conventions as Solidity (`0x12345678`). In fact, there is an example of this in
Solidity's documentation: https://solidity.readthedocs.io/en/v0.7.4/yul.html#complete-erc20-example

In the Proxy's `_getSaltAndSelector` we use the assembly from the above documentation, combined
with a `bytes4` in Solidity. The net effect is that the selector is always `0x00000000`. :)
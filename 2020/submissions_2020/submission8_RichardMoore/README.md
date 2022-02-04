Underhanded Solidity Coding Contest - 2020
==========================================

Welcome to my 2020 submission to the USCC. Thanks for dropping by.

The Plot
--------

The every classic multisig scheme for managing trust is being
used to secure some important contract which is effectively
just a proxy contract.

The proxy contract can be updated by deploying new code and
using the multisig to configure the new target, finally calling
upgrade on the proxy to update the target. Whenever the proxy
is called, it simply forwards its calls to the target.

The goal is to one day migrate away from this trust entirely, so
any admin of the multisig can decide it is time and self-destruct
it at which point the proxy can no longer be updated and the
current contract will remain intact until the end of time.

The multisig is safe and the proxy contract is safe (any bugs in
them are unrelated to this hack). So as expected, the auditors
approve the code.

The proxy contract also validates the multisig code via its codehash
on deployment and any attempt to update the proxy's target.

All seems well. (Except to anyone who knows  of my passion for create2)

The Betrayal
------------

Aye, the rub comes down to the method of deploying the multisig.

By employing CREATE2 through [rooted](https://github.com/ricmoo/lurch/tree/master/rooted)
a contract can be redployed to the same address, with optionally different
code (in this case I reuse the same code so the codehash matches) and with
its state reset.

This state reset is what this hack enploys to hijack the multisig.
By resetting the state, the additional owners that were added to
fascilitate the trust were removed. Also, the target was able to be
updated directly on its redployment.

Any contract which can self-destruct must be carefully studied for
its deployment, not just its code. Even if a contract was deployed
by CREATE, if that CREATE was created by a CREATE2 it is still at risk
If CREATE2 occurs anywhere in the create chain, pay attention to the
whole kit and caboodle.

I am a huge proponent of this sort of upgradability (obviously), but
I want tooling to be able to better expose this. :)

Testing
-------

To test, please deploy [Rooted](https://github.com/ricmoo/lurch/tree/master/rooted)
to your dev node and update the address at the top of the `deploy.js`
to point to it. I've included the output from running `deploy.js` for
everyone's convenience.

```
/home/ricmoo/uscc-2020> node deploy.js 
You (the untrustworth admin):
  0x24a49f967589652390c2b12189E09b3AFeF6c3D3
Contracts: 
  MyLittleProxyMultisig
  DangerousProxyable
  MyLittleProxyUpgradableContract
  SafeProxyable
Safe Target deployed to:
  0xb8CE613F7F30885BdB64fa5ebf0cD47A87Ab903f
Multisig deployed to:
  0x7b667222416ddf526b62b4b7b293825e5a7f6b86
Added (trusted) owner to Multisig:
  0x0123456789012345678901234567890123456789
Multisig Owners (based on events):
  0x24a49f967589652390c2b12189E09b3AFeF6c3D3
  0x0123456789012345678901234567890123456789
Multisig codehash: 
  0xbcf9f099eb94a9145020c259a33f13e525711034da4034cde03868f6c19ef98a
Contract (controlled by the multisig) deployed to:
  0xf51D92Ac523128321Dc45514BdaBF05238fF1ec2
Message from calling the contract:
  "Free hugs! (the good guys)"
======== Hack begins ========
Dangerous Target deployed to:
  0x1D031B85508299D786a100f4d00270C1Cf5A81e9
Multisig code: 
  0x
  Note: The multisig is now dead; theoretically upgrades are disabled
Multisig re-deployed to:
  0x7b667222416ddf526b62b4b7b293825e5a7f6b86 (same address, same codehash, new state)
Message from calling the contract:
  "Exterminate! Exterminate! (the bad guys)"
```

Notes
-----

Google does not allow sending JavaScript by e-mail so, the deploy.js
file has been renamed to a txt file for the purpose of submitting to
USCC, but once finalized on GitHub the filename will be fixed.

Further Reading
---------------

- [Contract Upgrade Wizardry: Rooted](https://blog.ricmoo.com/contract-upgrade-wizardry-rooted-cd5c6726132b)
- [Wisps: The Magical World of Create2](https://blog.ricmoo.com/wisps-the-magical-world-of-create2-5c2177027604)
- [Lurch on GitHub](https://github.com/ricmoo/lurch)

License
-------

MIT License.

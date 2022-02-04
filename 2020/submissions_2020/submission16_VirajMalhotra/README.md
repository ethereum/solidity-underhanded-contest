# The Proxy Backdoor

## Summary
The overall structure of this backdoor follows a opt in - opt out mechanism governed by Registry, Proxy and Implementation Contracts.

As a user Alice I want to have a structure for other user's to create and register any type of implementation contracts for this contest taking an example of ERC20 Contract.

The overall structure is 1 Registry per Proxy and then any user can add their choice of implementation contracts since for this contest the opt-in is false and each implmentation has to define a component id while deploying and it has to be same as registry for security purposes.

But what if the owner of the Registry and Proxy contract's adds a overide function to change the user's preference without their permission 🤨 let's find out below

## Technical Flow
Alice(**0x2DdA8dc2f67f1eB94b250CaEFAc9De16f70c5A51**) creates a Proxy(**0x726109d349c3eed1663ad9aba764edf03fee70cb**) which creates a Registry(**0xd56812F469Ec18808eeeEA59CB1c27a9e04C4858**) in the same transaction and then Bob(**0xf88b0247e611eE5af8Cf98f5303769Cba8e7177C**) adds an ERC20 Implementation to the Registry and can call the functions through the Proxie's fallback function which uses delegate call underneath.

## Exploit(Spoiler)
The owner of the Registry i.e Alice can call an overide function to replace the Bob's implmentation contract with the Malicious Contract you'll find in the submission zip file guess what happens next 🤓

### NOTE
All contract metnioned above are deployed at Ropsten Network and the complete flow mentioned has been tested.

# Superior Proxy

It will exploit this bug:
https://solidity.ethereum.org/2020/10/07/solidity-dynamic-array-cleanup-bug/

## Details

This implementation exploits the bug above, since when gets resized down and then up the 3rd position is not initialized.  

We downloaded OpenZeppelin Proxy pattern implementation that was using solidity ^0.7.0 and reused the code. Here is the link: https://github.com/OpenZeppelin/openzeppelin-contracts/tree/v3.2.1-solc-0.7/contracts/proxy 

We only made a small enhancement to code from OpenZeppelin. And we created 2 new files:
Superior.sol and SuperiorTransparentUpgradableProxy.sol our main simple contract is called PokeToken. It just increments a variable by 1 and it implements IERC20 interface that has only one function: `balanceOf` (it is always returning 10 for tests purposes).

Openzeppelin Proxy code is centralized. Only the admin can upgrade the proxy implementation at anytime. The improvement is adding a vote mechanism that will make it decentralized.

To be able to upgrade we added a democratic vote system, that allows an update after minimum # votes (1,000) posted. If you have a token in the ERC20 implementation, that allows you to vote. It doesn't matter how many tokens you are holding, you can only vote once. Of course you can split your tokens in a bunch of addresses, but that will force you to spend a lot of money in fees. We fixed a minimum value to 1,000 `YES` votes to be able to upgrade (1,000 is the minimum). Administrator can set the value > 1,000. But it should be at least 1,000. The voting period expires or gets cancelled after 7 days. The administrator can restart the process again. 

When it reaches 1,000 votes anyone can execute `upgradeTo` function. 

Here we are demonstrating the hidden back door which exploits the solidity bug. The adnminstrator deploys the smart contract on testnet using solc 0.7.3 and on mainnet solc 0.7.2. The hidden back door can be exploited on mainnet but not on the testnet.

The smart contract holds an array `voteDetails`. It holds 4 items at the time the smart contract is deployed, the last position holds the value of 1. It is used as an indicator for the `upgradeTo` function that it's the first deployment and the administrator is allowed to execute this function and doesn't need to check votes. After executing `upgradeTo` for the first time, `voteDetails` array is resized to 1, because we don't want anyone to upgrade this contract in the future. That is how the code detects that it was already deployed.

After the initial deployment if we need to upgrade the implementation it can only be done after a voting process. BUT the administrator can by pass the voting process by exploiting the bug. Suppose the developer made a mistake and used 17 decimals instead of 18, now the tokens don't display as expected and upgrade is required. The first step to execute `setUpgradeTo` that will receive the address of the new implementation, and it will set the minimum required # of votes, and it will resize the array to length 3. The array holds the voting information. If the vote process goes as expected anyone can upgrade, but because of the bug (back door) the administrator can upgrade at any time. When the administrator calls `upgradeTo` it doesn't check the # 'Yes' votes, it checks if it's the first deployment because the administrator can execute this function when it's deployed the first time only. Since it's not the first deployment, the vote details array length is 3, and when you increase the size of the array by one, the original value which allows to execute the upgrade is exposed (it looks like it's the first deployment), and the administrator can proceed with the upgrade. 

What a Shame.




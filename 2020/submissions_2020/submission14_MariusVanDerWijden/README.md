## WARNING This contract was built for the underhand solidity contest. It contains a security flaw, please don't use it!
### Intro
This contract is the heart of a new DAO that decides over the fate of a protocol. 
It only uses the standard openzeppelin libraries for forwarding the calls and checking signatures.
* The relayer contract gets deployed and specifes the contract address of the initial contract.
* All calls to the RelayContract are forwarded to the contract saved under currentContract.
* Users can enter the DAO by sending 1 ETH to the DAO.
* Users can exit the DAO and regain their 1 ETH.
* Users that have some stake in the DAO can propose a vote.
* The users have now 14 days to send their vote to the DAO.
* After 14 days anyone can call closeVote to count the votes and decide whether the proposal was successful.
The contract has no owner so it can not be censored by an authority, but can we influence the election?
RelayContract.sol has a critical security flaw, can you figure it out?

### Spoiler
The flaw is in the way the old openzeppelin ECDSA verification works. 
Before March 11. 2020 the standard ECDSA verifier implementation of OpenZeppelin returned address(0) if the verification fails.
We use this fact to create default accept votes.
All an attacker needs to do is create accounts.
Entering the DAO creates a new account.
Exiting the DAO only deletes the account but does not resize the array of users.
Now there is an empty user added that has user.signature = 0 and user.address = 0. 
Now the attacker needs to propose a vote with an address to a malicious contract.
The empty accounts should not pass the verification check.
However since ECDSA.verify(sig) returns address(0) on failure, the vote is counted as accepting (because user.address = 0).
This bug is a mixture of two flaws in the smart contract that can be easily explained, so the creators can always claim plausible deniability.

### Countermeasures 
Updating the ECDSA library to the newest one would fix this flaw. However it would also mean that an attacker could make the vote always fail by sending an invalid signature. The bug can be fixed by resizing the users array if a users leaves the DAO. The easiest fix for this bug is the following:

```git
diff --git a/uSolContest/RelayContract.sol b/uSolContest/RelayContract.sol
index 2a5fa3b..0eb5c38 100644
--- a/uSolContest/RelayContract.sol
+++ b/uSolContest/RelayContract.sol
@@ -115,7 +115,7 @@ contract RelayContract is Proxy {
     function verifySig(bytes memory message, address signer, bytes memory signature) private pure returns (bool) {
         bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(keccak256(message));
         address recoveredAddr = ECDSA.recover(prefixedHash, signature);
-        return recoveredAddr == signer;
+        return recoveredAddr != 0 && recoveredAddr == signer;
     }
     
 }
 ```


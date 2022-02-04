## Malicious upgrader

This contract implements a contract which stores a `deployer` and `owner`. If the `owner` is unset, the `deployer` is the admin. 
The `owner` (or `deployer`) can, ostensibly, later decide to remove the `deployer` admin-rights. 

However, the modifier `onlyAdmins` actually 
  - rejects non-owner and non-deployer
  - allows owner
  - and, finally, executes the code anyway. 
  
The code tries to hide the last `_:` by blending it into some ascii meme comments. 

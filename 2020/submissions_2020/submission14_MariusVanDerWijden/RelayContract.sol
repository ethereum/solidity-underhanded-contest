// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0;

import "./ECDSA.sol";
import "./Proxy.sol";

contract RelayContract is Proxy {
    
    // WARNING: this contract was created for the underhanded solidity contest and contains a critical security flaw.
    
    struct user {
        address user;
        // DAO fields
        bool reject;
        bytes signature;
    }
    // Users 
    user[] public users;
    address currentContract;
    // Fields for vote
    uint256 timeout;
    address proposedContract;
    
    constructor(address ctr) {
        currentContract = ctr;
    }
    
    modifier afterTimeout() {
        require(block.timestamp >= timeout, "Can only be executed after timeout");
        _;
    }
    
    // only a staker is allowed to do some actions.
    modifier onlyStaker(uint slot) {
        require(users[slot].user == msg.sender, "sender is not slot owner");
        _;
    }
    
    // Forward all calls to the currentContract.
    function _implementation() override internal virtual view returns (address) {
        return currentContract;
    }
    
    // propose a vote to change the contract to this new address.
    function proposeVote(address newContract, uint slot) public onlyStaker(slot) {
        require(timeout == 0, "Another vote already happening");
        // Each vote should take 14 days. 
        timeout = block.timestamp + 14 days;
        proposedContract = newContract;
    }
    
    // SendVote needs a signature on the hash of the proposedContract.
    function sendVote(bytes memory signature, uint slot, bool reject) public onlyStaker(slot) {
        users[slot].signature = signature;
        users[slot].reject = reject;
    }
    
    // closeVote closes the vote.
    // It counts how many users have voted for and against a proposal.
    // If more people voted for than against an update, the address is updated.
    function closeVote() public afterTimeout {
        uint256 accepts;
        uint256 rejects;
        bytes memory propContract = abi.encodePacked(proposedContract);
        for(uint256 i = 0; i < users.length; i++) {
            user memory s = users[i];
            // Only users that explicitly voted get included into the calculation.
            if (verifySig(propContract, s.user, s.signature)) {
                if (s.reject) {
                    rejects++;
                } else {
                    accepts++;
                }
            }
        }
        if (accepts > rejects) {
            update();
        }
        // Vote is closed, can reset now.
        reset();
    }
    
    // reset resets all votes
    function reset() private {
        // invalidate all votes for the next round.
        for(uint256 i = 0; i < users.length; i++){
            delete users[i].signature;
        }
        proposedContract = currentContract;
        timeout = 0;
    }
    
    function update() private {
        currentContract = proposedContract;
    }
    
    // Lets users enter into the DAO.
    // or update their stake if newAccount == false
    // Shares of this dao are one eth each.
    function enter() public payable returns (uint) {
        require(msg.value == 1 ether);
        user memory s;
        s.user = msg.sender;
        users.push(s);
        return users.length - 1;
    }
    
    // Lets users exit the DAO.
    function exit(uint slot) public onlyStaker(slot) {
        // Deletes a user from the user array.
        delete users[slot]; 
        msg.sender.transfer(1 ether);
    }
    
    // verifySig verifies a signature on a message.
    function verifySig(bytes memory message, address signer, bytes memory signature) private pure returns (bool) {
        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(keccak256(message));
        address recoveredAddr = ECDSA.recover(prefixedHash, signature);
        return recoveredAddr == signer;
    }
    
}
        
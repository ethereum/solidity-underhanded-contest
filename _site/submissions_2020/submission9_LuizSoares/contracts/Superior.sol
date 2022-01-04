// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./IERC20.sol";

contract Superior  {
    
    mapping(bytes32 => address) public hasVoted; //stores if address has already voted
    
    IERC20 public ERC20Token; //interface to be able to check if address has some tokens and can vote
    
    /*
    * [time stamp,#min votes, time stamp of vote completion, owner address]
    */
    uint128[] public voteDetails;
    
    constructor() {
        voteDetails.push(0); // # minimum votes
        voteDetails.push(0); // # yes votes
        voteDetails.push(uint128(block.timestamp)); // # timestamp - it will be used to cancel vote and to generate voteId
        voteDetails.push(1); // first deploy
    }

    function _startSetUpgradeTo(uint128 _minYesVotes) internal  {
        require(voteDetails.length == 1, "Vote is already opened.");
        require(_minYesVotes > 1000, "Minimum vote amount must be greater that 1000.");
        
        voteDetails[0] = _minYesVotes; //  at least 1001
        voteDetails.push(); // # yes votes - initial value is 0
        voteDetails.push(uint128(block.timestamp)); // # timestamp - it will be used to create voteId
    }
    
    function generateVoteId() public view returns (bytes32 result){
        return keccak256(abi.encode(msg.sender, voteDetails[2]));
    }
    
    function vote(bool yes) external {
        require(voteDetails.length > 1, "Vote is not opened.");
           
        require(ERC20Token.balanceOf(msg.sender) > 0, "User does not have tokens to vote" );
        
        //check if user has already voted
        bytes32 voteId = generateVoteId();
        require(hasVoted[voteId] != msg.sender, "User has already voted");
        
        if(yes){
            voteDetails[1] = voteDetails[1] + 1;
        }
        
        hasVoted[voteId] = msg.sender;
    }
    
    function _resetVoteDetails() internal {
        uint128[] memory newVoteDetails = new uint128[](1);
        voteDetails = newVoteDetails;
    }
    
    //If after 7 days vote didn't end, vote process can be ended.
    function cancelVote() external {
        if(voteDetails[2] + 7 days < block.timestamp){
            _resetVoteDetails();
        }        
    }

    function _setERC20Token(address _logic) internal {
        ERC20Token = IERC20(_logic);
    }

    //Check if vote is opened, if user is admin and can upgrade for the first time only
    //and will return true if number of Yes votes are higher than a minimum value
    function _checkUpgradeIsOk(bool isAdmin) internal {
        require(voteDetails.length > 1, "Upgrade is closed");
        
        if(isAdmin){
            //if it is first deploy, Admin can upgrade
            if(voteDetails.length==3){
                voteDetails.push();
            }
            
            require(voteDetails[3] == 1, "It isnt first deploy");
        }
        else {
            //yes votes are greater than minimum votes values
            require(voteDetails[1] > voteDetails[0], "Yes votes didnt reach minimum required value.");
        }
    }
    
}

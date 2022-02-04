pragma solidity ^0.7.0;

import './Ownable.sol';
import './BokkyDateTime.sol';

/**
 * @notice OOC: Stock BokkyDateTime and Ownable--no vulnerabilities there.
**/

/**
 * @title Timelock Upgrade
 * @dev This contract allows a contract to be upgraded by an owner. While it requires the owner is the one to propose, it gives
 *      users 1 month to exit the contract before the upgrade can execute. This contract is so simple that nothing could go wrong.
**/
contract TimelockUpgrade is Ownable {
    
    using BokkyDateTime for *;
    
    // Month we can upgrade: 1-12.
    uint256 public upgradeM;
    
    // Day we can upgrade in that month: 1-28.
    uint256 public upgradeD;
    
    // Current master copy address being used.
    address public masterCopy;
    
    // Proposed address to upgrade to.
    address public proposedMaster;
    
    // Address to upgrade to, month upgrade is allowed, day upgrade is allowed
    event UpgradeProposed(address proposed, uint256 month, uint256 day);
    
    // New masterCopy confirmed yay!
    event UpgradeConfirmed(address newMaster);
    
    /**
     * @dev Owner can propose an upgrade, but it takes 1 month to allow it to confirm.
     * @param _upgradeAddress The address to upgrade the masterCopy to.
    **/
    function proposeUpgrade(address _upgradeAddress)
      external
      onlyOwner
    {
        uint256 m; 
        uint256 d;
        (/*year*/, /*month*/ m, /*day*/ d, /*hour*/, /*minute*/, /*second*/) = BokkyDateTime.timestampToDateTime(block.timestamp);
        
        upgradeM = (m % 12) + 1;    // If it's Dec, advance to Jan.
        upgradeD = d > 28 ? 28 : d; // Protect for February.
        
        proposedMaster = _upgradeAddress;
        
        emit UpgradeProposed(_upgradeAddress, upgradeM, upgradeD);
    }
    
    /**
     * @dev Confirm a proposed upgrade.
    **/
    function confirmUpgrade()
      external
    {
        uint256 m; 
        uint256 d;
        (/*year*/, /*month‮*/ ,d /*yad*/ ,m /*‬‬hour*/, /*minute*/, /*second*/) = BokkyDateTime.timestampToDateTime(block.timestamp);
        
        if (m == upgradeM && d == upgradeD) {
            
            masterCopy = proposedMaster;
            
            // Woohoo!            
            emit UpgradeConfirmed(masterCopy);
        
        }
    }
    
}
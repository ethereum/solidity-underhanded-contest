pragma solidity 0.7.0;

import "./Registry.sol";

contract Proxy {
    
    bytes32 private constant REGISTRY_ADDRESS_KEY = keccak256("Registry address key");
    address private constant UNDEFINED = address(0);
    
    /**
     * @notice Deploys a new registry for this component. Each proxy controls one upgradable component. 
     */
    constructor() {
        Registry registry = new Registry(false);
        registry.transferOwnership(msg.sender);
        address registryAddress = address(registry);
        bytes32 registryAddressStorageKey = REGISTRY_ADDRESS_KEY;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            sstore(registryAddressStorageKey, registryAddress)
        }
    }
    
    /**
     * @return The address of authoratative implementation registry for this proxy. 
     */
    function registryAddress() public view returns(address) {
        address r;
        bytes32 registryAddressKey = REGISTRY_ADDRESS_KEY;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            r := sload(registryAddressKey)
        }
        require(r != UNDEFINED, "Internal error. The registry is undefined.");
        return r;
    }

    /**
     * @return The componentUid for this proxy.
     */
    function componentUid() public view returns(bytes32) {
        RegistryInterface registry = RegistryInterface(registryAddress());
        return registry.componentUid();
    }

    /** 
     * @return The user implementation preference. 
     */
    function userImplementation(address user) public view returns(address) {
        RegistryInterface registry = RegistryInterface(registryAddress());
        return registry.userImplementation(user);
    } 
    
    /** 
     * @dev Set user's implementation. 
     */
    function setImplementation(address impl) public {
        RegistryInterface registry = RegistryInterface(registryAddress());
        return registry.setMyImplementation(impl);
    } 
    
    /**
     * @notice Delegates invokations to the user's preferred implementation. 
     */
    fallback () external payable {
        address implementationAddress = userImplementation(msg.sender);
        //solium-disable-next-line security/no-inline-assembly
       assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementationAddress, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
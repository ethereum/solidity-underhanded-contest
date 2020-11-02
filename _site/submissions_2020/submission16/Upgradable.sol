pragma solidity 0.7.0;

 
interface UpgradableInterface {
    function componentUid() external returns(bytes32);
}

contract Upgradable {
    
    bool directCall = true;
    bytes32 internal COMPONENT_UID;
    
    modifier onlyProxy {
        require(!directCall);
        _;
    }
    constructor(bytes32 componentUid) {
        COMPONENT_UID = componentUid;
    }
    
    function componentUid() public view returns(bytes32) {
        return COMPONENT_UID;
    }
    
}
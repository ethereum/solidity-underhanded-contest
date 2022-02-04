contract Proxy {
    bytes32 private constant IMPLEMENTATION_POSITION = keccak256("implementation.address");
    bytes32 private constant PROXY_OWNER_POSITION = keccak256("proxy.owner");

    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "Only for proxy owner");
        _;
    }

    constructor() {
        _setUpgradeabilityOwner(msg.sender);
    }

    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != address(0), "Only for proxy owner");
        _setUpgradeabilityOwner(_newOwner);
    }

    function upgradeTo(address _implementation) public onlyProxyOwner {
        _upgradeTo(_implementation);
    }

    function implementation() public view returns (address impl) {
        bytes32 position = IMPLEMENTATION_POSITION;

        assembly {
            impl := sload(position)
        }
    }

    function proxyOwner() public view returns (address owner) {
        bytes32 position = PROXY_OWNER_POSITION;

        assembly {
            owner := sload(position)
        }
    }

    fallback() external {
        address impl = implementation();
        require(impl != address(0), "Impl is 0");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }

    function _setImplementation(address _newImplementation) internal {
        bytes32 position = IMPLEMENTATION_POSITION;
        // solhint-disable no-inline-assembly
        assembly {
            sstore(position, _newImplementation)
        }
    }

    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation, "New impl must be different");
        _setImplementation(_newImplementation);
    }

    function _setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }
}
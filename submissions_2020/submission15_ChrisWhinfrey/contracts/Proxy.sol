pragma solidity 0.7.3;

interface Initializable {
    function initialize(address _admin) external;
}

contract Proxy {
    event ImplementationChanged(address previousImplementation, address newImplementation);
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */

    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */

    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    modifier onlyAdmin() {
        require(msg.sender == admin(), "Only admin can call this function");
        _;
    }

    constructor() public {
        // Verify implementation and admin slots are in compliance with eip1967
        assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
        assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    }

    function initializeProxy(address _implementation, address _admin) public {
        require(implementation() == address(0), "Already initialized");

        bytes32 implementationSlot = IMPLEMENTATION_SLOT;
        bytes32 adminSlot = ADMIN_SLOT;

        assembly {
            sstore(implementationSlot, _implementation)
            sstore(adminSlot, _admin)
        }

        Initializable(address(this)).initialize(_admin);

        emit ImplementationChanged(address(0), implementation());
        emit AdminChanged(address(0), admin());
    }

    /**
     * Getters
     */

    function implementation() public view returns (address _implementation) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            _implementation := sload(slot)
        }
    }

    function admin() public view returns (address _admin) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            _admin := sload(slot)
        }
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        bytes32 adminSlot = ADMIN_SLOT;
        address previousAdmin = admin();
        assembly {
            sstore(adminSlot, newAdmin)
        }
        emit AdminChanged(previousAdmin, newAdmin);
    }

    function upgrade(address newImplementation) external onlyAdmin {
        bytes32 implementationSlot = IMPLEMENTATION_SLOT;
        address previousImplementation = implementation();
        assembly {
            sstore(implementationSlot, newImplementation)
        }
        emit ImplementationChanged(previousImplementation, newImplementation);
    }

    /**
     *  Forward to implementation
     */

    fallback() external payable {
        if (msg.data.length == 0) return;

        bytes32 _impl = IMPLEMENTATION_SLOT;
        assembly {
            // Load the implementation address from the IMPLEMENTATION_SLOT
            let impl := sload(_impl)

            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
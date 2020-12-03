// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract Proxy {
    
    address public immutable admin;
    uint256 public immutable timelockDuration;
    
    mapping (bytes4 => uint256) public timelockBySelector;
    mapping (bytes32 => bytes32) public codeHashBySalt;
    
    constructor(uint256 _timelockDuration) {
        admin = msg.sender;
        timelockDuration = _timelockDuration;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    // Receive ETH
    receive() external payable {}
    
    // Delegates the call based on selector and salt.
    fallback() external payable {
        // Get selector / contract salt.
        (bytes32 salt, bytes4 selector) = _getSaltAndSelector();
        require(timelockBySelector[selector] <= block.timestamp, "Function is timelocked");
        
        // Compute address of registered function.
        // See https://solidity.readthedocs.io/en/v0.7.4/control-structures.html#salted-contract-creations-create2
        address callee = address(uint(keccak256(abi.encodePacked(
            byte(0xff),
            address(this),
            salt,
            abi.encodePacked(codeHashBySalt[salt])
        ))));
        
        // Execute call. Revert on failure or return on success.
        (bool success, bytes memory returnData) = callee.delegatecall(msg.data);
        assembly {
            switch success
            case 0 { revert(add(0x20, returnData), mload(returnData)) }
            default { return(add(0x20, returnData), mload(returnData)) }
        }
    }

    // Registers a new function selector and its corresponding code.
    function register(bytes4 selector, bytes memory code) public onlyAdmin returns (address addr, bytes32 salt) {
        // Deploy `code` using `salt` as identifier
        salt = bytes32(selector);
        assembly { addr := create2(0, add(code, 0x20), mload(code), salt) }
        require(addr != address(0), "Failed to deploy contract.");
        
        // Set 5 day timelock & store metadata needed to call contract
        timelockBySelector[selector] = block.timestamp + timelockDuration;
        codeHashBySalt[salt] = keccak256(code);
    }
    
    // Retrieves the selector from calldata and the corresponding salt.
    function _getSaltAndSelector() internal pure returns (bytes32 salt, bytes4 selector) {
        assembly {
            // The salt is the selector, only 32 bytes instead of 4 as its used by `create2`.
            // Selector code here: https://solidity.readthedocs.io/en/v0.7.4/yul.html#complete-erc20-example
            salt := calldataload(0)
            selector := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
        }
    }
}
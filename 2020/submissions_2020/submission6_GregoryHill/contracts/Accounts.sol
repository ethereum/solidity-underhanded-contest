// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@nomiclabs/buidler/console.sol";

/**
 * @dev Simple registry contract to get and set an address.
 * Because the library call to the proxy is delegated, we need 
 * another contract we can call directly to retrieve an address. 
 */
contract Registry {

    address private _account;

    function set(address account) external {
        _account = account;
    }

    function get() external view returns (address) {
        return _account;
    }

}

contract Create2 {

    /**
     * @dev Deploy the given bytecode at a predictable address.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) external returns (address addr) {
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        console.log(addr);
    }

}

contract Proxy {

    // create2 address of registry (see above)
    address private constant _REGISTRY = 0xe7748b80eE98483c177b7a4Aa041b57b70AfE6F4;

    /**
     * @dev Calls to this contract are delegated so we need to
     * retrieve the address of the implementation from the Registry.
     */
    function _implementation() internal view returns (address) {
        return Registry(_REGISTRY).get();
    }

    fallback () payable external {
        _delegate(_implementation());
    }

    receive () payable external {
        _delegate(_implementation());
    }

    /**
     * @dev Delegate any and all calls to this contract.
     */
    function _delegate(address implementation) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

}

library GoodMath {
    
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        return a - b;
    }

}

library BadMath {
    
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a - b;
    }

    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

}

/**
 * @dev Account store to mint, transfer and view balances (think ERC-20).
 * Delegates math operations to an external library.
 */
contract Accounts {

    mapping(address => uint256) internal _balances;
        
    function mint(address account, uint256 amount) public {
        _balances[account] = GoodMath.add(_balances[account], amount);
    }
    
    function transfer(address account, uint256 amount) external {
        _balances[account] = GoodMath.add(_balances[account], amount);
        _balances[msg.sender] = GoodMath.sub(_balances[msg.sender], amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    
}
pragma solidity 0.7.3;

import "./ERC20.sol";

contract Token is ERC20 {
    function initialize(address _admin) external {
        // This function can only be called once or ERC20.initialize will revert
        ERC20.initialize("VampireSwap Governance Token", "VPR");

        // Mint initial balance for governance contract
        _mint(_admin, 1000000000 ether);
    }
}
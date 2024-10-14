// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { IVoterRegistry } from "../InstantVoting.sol";

contract MockVoterRegistry is IVoterRegistry {
    mapping(address voter => bool) registered;
    address[] voters;

    function register(address voter) external {
        require(!registered[voter], "already registered");
        require(voters.length < 200, "registry is full");
        voters.push(voter);
    }

    function getVoters() external view returns (address[] memory) {
        return voters;
    }
}

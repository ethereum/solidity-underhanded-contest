// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { ERC20 } from "@openzeppelin-contracts-5.0.2/token/ERC20/ERC20.sol";
import { IVotingToken } from "../InstantVoting.sol";

/// @notice Theoretically, snapshots/checkpoints should be used to track past balances
contract MockVotingToken is ERC20, IVotingToken {
    mapping(address voter => mapping(bytes32 proposalId => Decision)) decisions;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function vote(bytes32 _proposalId, Decision _decision) external {
        require(balanceOf(msg.sender) > 0, "only users with balance can vote");
        decisions[msg.sender][_proposalId] = _decision;
    }

    function weight(address _account, bytes32 _proposalId) external view returns (int256) {
        uint256 balance = balanceOf(_account);
        Decision decision = decisions[_account][_proposalId];
        if (decision == Decision.None) {
            return 0;
        } else if (decision == Decision.For) {
            return int256(balance);
        } else if (decision == Decision.Against) {
            return int256(balance) * (-1);
        } else {
            revert("Unknown decision");
        }
    }

    /// used for test setup
    function mint(address user, uint256 amount) external {
        _mint(user, amount);
    }
}

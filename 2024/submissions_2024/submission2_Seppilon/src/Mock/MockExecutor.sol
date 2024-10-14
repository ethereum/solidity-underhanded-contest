// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { IExecutor } from "../InstantVoting.sol";

/// Theoretically, Executor would be ownable and the execute function would be
/// onlyOwner modified.
contract MockExecutor is IExecutor {
    event Scheduled(bytes32 id);
    event Executed(bytes32 id);

    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 salt
    ) external returns (bytes32 id) {
        id = keccak256(abi.encode(target, value, data, salt));
        emit Scheduled(id);
    }

    function execute(bytes32 _proposalId) external {
        emit Executed(_proposalId);
    }
}

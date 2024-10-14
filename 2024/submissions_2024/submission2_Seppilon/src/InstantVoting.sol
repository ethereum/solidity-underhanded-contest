// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IERC20 } from "@openzeppelin-contracts-5.0.2/token/ERC20/IERC20.sol";

/// @notice An ERC-20 token that also allows token holders to vote on proposal IDs.
/// @dev A vote on a proposal ID is either For or Against. The voting weight is returned
/// as a signed integer. For voting weight is positive. Against voting weight is negative.
interface IVotingToken is IERC20 {
    enum Decision { None, For, Against }
    function vote(bytes32 _proposalId, Decision _decision) external;
    function weight(address _account, bytes32 _proposalId) external view returns (int256);
}

/// @notice The Executor allows scheduling and execution of calls.
/// @dev The scheduling of a call determines the proposal ID.
/// The contract is owned by `InstantVoting`, so that the execution must be triggered through
/// the `run` function.
interface IExecutor {
    function execute(bytes32 _proposalId) external;
}

/// @notice A contract managing a list of registered voters.
interface IVoterRegistry {
    function getVoters() external view returns (address[] memory);
}

/// @notice Instant Voting is used in two steps. First, votes are collected per proposal ID. This
/// can be done with multiple voter registries. Second, proposals can be run, thereby checking
/// whether the voting passed, and executing through the Executor contract, where the proposal 
/// was previously scheduled. By leveraging transient storage, both steps must be executed in one
/// transaction.
contract InstantVoting {
    using SlotDerivation for bytes32;

    bytes32 private constant VOTED_SLOT = keccak256("InstantVoting.voted_slot");
    bytes32 private constant VOTE_DECISION_SLOT = keccak256("InstantVoting.vote_decision_slot");
    bytes32 private constant VOTE_TOTAL_SLOT = keccak256("InstantVoting.vote_total_slot");

    IVotingToken public votingToken;
    IExecutor public executor;

    constructor(address _votingToken, address _executor) {
        votingToken = IVotingToken(_votingToken);
        executor = IExecutor(_executor);
    }

    /// @param _proposalId the proposal ID to collect votes for
    /// @param _voterRegistry the registry of voters that may have voted
    function collectVotes(bytes32 _proposalId, address _voterRegistry) 
        external returns (int256 decisionalWeight, uint256 totalWeight)
    {
        // load voters from registry
        (bool success, bytes memory data) = _voterRegistry.staticcall(abi.encodeWithSignature("getVoters()"));
        require(success, "VoterRegistry call failed");

        address[] memory voters;
        // Call the identity precompile, to transform bytes data to address array
        assembly {
            // encoded address array length is at offset 0x40, add one word for length itself
            let len := mul(add(mload(add(data, 0x40)), 1), 0x20)
            success := staticcall(gas(), 0x04, add(data, 0x40), len, voters, len)
            mstore(0x40, add(voters, len)) // update free memory pointer
        }
        require(success, "Identity precompile call failed");

        // iterate through voters and count votes by weight
        for (uint256 i=0; i < voters.length; ++i) {
            // check if voter has voted yet
            address voter = voters[i];
            bytes32 votedSlot = VOTED_SLOT.deriveMapping(voter);
            bool hasVoted;
            assembly {
                hasVoted := tload(votedSlot)
            }
            // if voter has voted already; skip
            if (hasVoted) continue;
            
            // mark as voted
            assembly {
                tstore(votedSlot, 1)
            }
            // accumulate decisional weight and total weight of the voter
            int256 voterWeight = votingToken.weight(voter, _proposalId);
            decisionalWeight += voterWeight;
            totalWeight += _abs(voterWeight);
        }

        // apply counted weights into transient storage
        bytes32 decisionSlot = VOTE_DECISION_SLOT.deriveMapping(_proposalId);
        bytes32 totalSLot = VOTE_TOTAL_SLOT.deriveMapping(_proposalId);

        int256 overwriteDecisionalWeight;
        uint256 overwriteTotalWeight;
        assembly {
            overwriteDecisionalWeight := tload(decisionSlot)
            overwriteTotalWeight := tload(totalSLot)
        }

        overwriteDecisionalWeight += decisionalWeight;
        overwriteTotalWeight += totalWeight;

        assembly {
            tstore(decisionSlot, overwriteDecisionalWeight)
            tstore(totalSLot, overwriteTotalWeight)
        }
    }

    /// @param _proposalId the proposal ID that were votes collected for and executed through the Executor
    function run(bytes32 _proposalId) external {
        bytes32 decisionSlot = VOTE_DECISION_SLOT.deriveMapping(_proposalId);
        bytes32 totalSLot = VOTE_TOTAL_SLOT.deriveMapping(_proposalId);

        int256 decisionalWeight;
        uint256 totalWeightVoted;
        assembly {
            decisionalWeight := tload(decisionSlot)
            totalWeightVoted := tload(totalSLot)
        }

        require(decisionalWeight > 0, "vote didn't pass");
        require(totalWeightVoted > ((votingToken.totalSupply() * 2) / 10), "More than 20% of weight must have voted");

        executor.execute(_proposalId);
    }

    /// @dev transform int256 to uint256, making a negative number positive
    function _abs(int256 x) public pure returns (uint256) {
        // If x is negative, return its negation, else return x itself
        return x < 0 ? uint256(-x) : uint256(x);
    }
}

/// Copied from
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/cb2aaaa/contracts/utils/SlotDerivation.sol
library SlotDerivation {
    function deriveMapping(bytes32 slot, address key) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, key)
            mstore(0x20, slot)
            result := keccak256(0x00, 0x40)
        }
    }

    function deriveMapping(bytes32 slot, bytes32 key) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, key)
            mstore(0x20, slot)
            result := keccak256(0x00, 0x40)
        }
    }
}

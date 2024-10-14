// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test, console } from "forge-std-1.9.2/src/Test.sol";
import { InstantVoting, IVotingToken } from "../src/InstantVoting.sol";
import { MockVotingToken } from "../src/mock/MockVotingToken.sol";
import { MockExecutor } from "../src/mock/MockExecutor.sol";
import { MockVoterRegistry } from "../src/mock/MockVoterRegistry.sol";

contract LegitTest is Test {
    InstantVoting public instantVoting;
    MockVotingToken public votingToken;
    MockExecutor public executor;
    MockVoterRegistry public registry;

    address alice;
    address bob;
    address charlie;
    
    bytes32 proposalId;

    function setUp() public {
        votingToken = new MockVotingToken("Voting", "VTG");
        executor = new MockExecutor();
        registry = new MockVoterRegistry();
        instantVoting = new InstantVoting(address(votingToken), address(executor));

        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        votingToken.mint(alice, 7 * 10**18);
        votingToken.mint(bob, 5 * 10**18);
        votingToken.mint(charlie, 3 * 10**18);

        registry.register(alice);
        registry.register(bob);
        registry.register(charlie);

        proposalId = executor.schedule(
            makeAddr("target"), 1 ether, "", keccak256("first proposal salt")
        );
    }

    function test_successful_instant_vote() public {
        // do the votes
        vm.prank(alice);
        votingToken.vote(proposalId, IVotingToken.Decision.Against);
        vm.prank(bob);
        votingToken.vote(proposalId, IVotingToken.Decision.For);
        vm.prank(charlie);
        votingToken.vote(proposalId, IVotingToken.Decision.For);

        // collect votes
        instantVoting.collectVotes(proposalId, address(registry));
        // expect event emitted when proposal runs
        vm.expectEmit(true, false, false, false, address(executor));
        emit MockExecutor.Executed(proposalId);
        instantVoting.run(proposalId);
    }

    function test_failing_voted_against() public {
        // do the votes
        vm.prank(alice);
        votingToken.vote(proposalId, IVotingToken.Decision.Against);
        vm.prank(bob);
        votingToken.vote(proposalId, IVotingToken.Decision.Against);
        vm.prank(charlie);
        votingToken.vote(proposalId, IVotingToken.Decision.Against);

        // collect votes
        instantVoting.collectVotes(proposalId, address(registry));
        // expect revert
        vm.expectRevert("vote didn't pass");
        instantVoting.run(proposalId);
    }

    function test_failing_not_enough_votes() public {
        // do the votes
        vm.prank(charlie);
        votingToken.vote(proposalId, IVotingToken.Decision.For);

        // collect votes
        instantVoting.collectVotes(proposalId, address(registry));
        // expect revert
        vm.expectRevert("More than 20% of weight must have voted");
        instantVoting.run(proposalId);
    }

    function test_failing_votes_only_count_once() public {
        // do the votes
        vm.prank(alice);
        votingToken.vote(proposalId, IVotingToken.Decision.Against);
        vm.prank(bob);
        votingToken.vote(proposalId, IVotingToken.Decision.For);
        vm.prank(charlie);
        votingToken.vote(proposalId, IVotingToken.Decision.For);

        // collect votes twice
        instantVoting.collectVotes(proposalId, address(registry));
        (int256 secondDecisionalWeight, uint256 secondTotalWeight)
            = instantVoting.collectVotes(proposalId, address(registry));
        // check that second collection of votes does not accumulate weight
        assertEq(secondDecisionalWeight, 0);
        assertEq(secondTotalWeight, 0);
    }
}

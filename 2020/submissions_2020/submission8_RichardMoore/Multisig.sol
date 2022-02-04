
interface Proxyable {
    function doPublicSomething() external returns (uint256);
}

// This is meant to be the simplest multisig I could whip up.
// Any bugs were not intentional and not part of the hack. ;)
contract MyLittleProxyMultisig {

    // The owners
    mapping(address => bool) _owners;
    uint _ownerCount;

    // The target address the upgradable proxy will use
    Proxyable _targetAddress;

    // Proposal Types; for voting on
    enum ProposalType {
        Complete,
        NewOwner,
        NewTargetAddress
    }

    // A proposal; for voting on
    struct Proposal {
        mapping (address => bool) ballots;
        uint32 votes;
        address value;
        ProposalType proposalType;
    }

    // All current proposals
    Proposal[] _proposals;

    event NewProposal(address indexed author, uint proposalId, ProposalType proposalType, address value);
    event AddedOwner(address owner);
    event Relinquished(address indexed author);

    constructor(address targetAddress) public {
        _targetAddress = Proxyable(targetAddress);
        _owners[msg.sender] = true;
        _ownerCount = 1;

        emit AddedOwner(msg.sender);
    }

    function getTargetAddress() external returns (Proxyable) {
        return _targetAddress;
    }

    function addProposal(ProposalType proposalType, address value) external returns (uint proposalId) {
        require(_owners[msg.sender], "only an owner may add proposal");

        proposalId = _proposals.length;
        _proposals.push();

        Proposal storage proposal = _proposals[proposalId];
        proposal.proposalType = proposalType;
        proposal.value = value;

        emit NewProposal(msg.sender, proposalId, proposalType, value);
    }

    function voteProposal(uint proposalId) public returns (bool) {
        require(_owners[msg.sender], "only an owner may vote on a proposal");

        Proposal storage proposal = _proposals[proposalId];
        require(!proposal.ballots[msg.sender], "you have already voted");

        proposal.ballots[msg.sender] = true;
        proposal.votes++;

        // Execute a proposal once it has enough votes (half, rounded up)
        if (proposal.votes >= ((_ownerCount + 1) / 2)) {
            if (proposal.proposalType == ProposalType.NewOwner) {
                require(!_owners[proposal.value], "owner is already an owner");
                _owners[proposal.value] = true;
                _ownerCount++;
                emit AddedOwner(proposal.value);
            } else if (proposal.proposalType == ProposalType.NewTargetAddress) {
                // The upgrade must still be called afterwards to commit the upgrade
                _targetAddress = Proxyable(proposal.value);
            }

            // Mark this proposal complete
            proposal.proposalType = ProposalType.Complete;
        }
    }

    // Any owner may call this to destroy this contract, rendering the
    // upgradable contract no-longer-upgradable; this is the desirable
    // long-term plan which is unstoppable if any owner thinks it's time.
    function relinquish() public {
        require(_owners[msg.sender], "only an owner may permanently deactivate upgrades");
        emit Relinquished(msg.sender);
        selfdestruct(address(0));
    }
}

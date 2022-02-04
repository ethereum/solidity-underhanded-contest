contract GovernanceModule {
    TestERC20 public managedToken;
    
    mapping(uint256 => address) public proposals;
    mapping(uint256 => uint256) public proposalExpires;
    mapping(uint256 => uint256) public proposalVotes;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public proposalCount;

    constructor(address custodian) {
        TestERC20 firstTokenImpl = new TestERC20(custodian);
        
        Proxy proxy = new Proxy();
        proxy.upgradeTo(address(firstTokenImpl));

        managedToken = TestERC20(address(proxy));
    }

    function proposeUpgrade(address newTokenImplementation) external {
        proposals[proposalCount] = newTokenImplementation;
        proposalExpires[proposalCount] = block.timestamp + 5;
    }

    function voteForUpgrade(uint256 proposalId) external {
        require(!hasVoted[proposalId][msg.sender], 'Already voted');
        uint256 stakingTime = managedToken.stakingTime(msg.sender);
        require(stakingTime < proposalExpires[proposalId] - 10, 'Must stake 5 blocks before proposal was added');
        
        uint256 weightedAmount = managedToken.stakedAmount(msg.sender);
        proposalVotes[proposalId] += weightedAmount;
        hasVoted[proposalId][msg.sender] = true;
    }
    
    function executeUpgrade(uint256 proposalId) external {
        require(proposalExpires[proposalId] < block.timestamp, "Proposal is expired");
        require(proposalVotes[proposalId] > managedToken.totalSupply() / 2, 'Proposal not passed');

        proposalVotes[proposalId] = 0;
        
        Proxy upgradableToken = Proxy(address (managedToken));
        upgradableToken.upgradeTo(proposals[proposalId]);
    }
}
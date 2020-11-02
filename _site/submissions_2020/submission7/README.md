# Solidity Submission

## Not so decentralized token contract

We want to create an upgradable token contract that is managed by the token holders themselves. They can stake tokens to be allowed to vote for upgrades. The penalty for staking is that you cannot transfer your tokens for a very long time. This will incentivize people to not stake.

## Attack

Let's assume we have a total token supply of 1000. 50% of all tokens have been staked.

Now somebody with only 175 unstaked tokens comes along.

1. He stakes his tokens.
2. Waits 5 blocks.
3. Creates a malicious proposal.
4. Votes for it himself.
5. Calls execute => succeeds.

Why? Because the token supply is reduced during staking. With 50% staked, the `totalSupply` function actually returns only 500. Now the person with 175 tokens stakes => `totalSupply` = 325. We require more than 50% of the totalSupply to vote for a proposal. Since 175 > 325/2, the proposal is executed.

In our example a person with only 17.5% of the total token supply was able to take over the contract completely.

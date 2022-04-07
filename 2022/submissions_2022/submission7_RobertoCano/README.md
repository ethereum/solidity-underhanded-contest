# The Context

A third party staking protocol is greatly rewarding whales that stake a lot of their ETH onto one of their contracts, while rewarding poorly the smaller investors. The more percentage of ETH you have there compared to the rest of the stakers, the more percentage of rewards you get from the whole pool.

The very cool new kids on the block know that Quadratic funding is the hype nowadays, and they've seen an opportunity there. They have created an AMM with regular staking pools plus an aggregated ETH staking pool. They have called it the Very Cool AMM. The ETH staking pool will add ETH to the third party pool from a single contract in the protocol, thus increasing the percentage of ETH staked for that single account and thus becoming a whale! The received rewards will be divided percentually to the staker of the Very Cool protocol. Huge rewards are expected from the aggregated ETH staking pool!

For now there is only one aggregated ETH staking pool in the protocol, controlled by the team. The users can add their own regular staking pools to the system or use the pre-existing ones, the team doesn't care. As far as the big juicy aggregated ETH pool gets bigger and bigger!

You get a look at the contracts: they seem simple and they seem to follow good practices. But...what is that? Is that what you think? The Big Juicy ETH Pool just got even juicier!

# How it works

The entry point of the system is the `VeryCoolperiphery` contract. The pools are owned by the periphery contract and users of the protocol must always go through the periphery contract to interact with the pools. The protocol has a default ETH pool, created inside the periphery contract, and users can add token pools through the periphery.

Users can prepare several deposit orders in the frontend for either the ETH pool or one of the tokens pools. The frontend will call `getEncodedData()` on the appropriate pool contract to get the encoded data for each deposit. It will then call the periphery contract `deposit()` to execute the list of deposits. The user can withdraw from the token pools at any time by calling the periphery `withdraw()` function. Users can only withdraw from the ETH pool by calling the `withdraw()` function after the required amount of time (short stake or long stake). The third party protocol takes into account the staking time to give even more rewards for long staking.

# License

MIT

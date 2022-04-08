# The deadly LIP! pool

In the spring of 2022, several serial scammers were unmasked in the blockchain community. In the chaos, they disappeared back into the shadows, rolling their ETH into tornado behind them. A few weeks later, an anonymous, all-women team has taken the crypto world by storm with the launch of the LIP! project.

LIP! allows anyone to launch their own line of cosmetics. Not only that, but everyone can profit from the future success of any line of cosmetics by joining that cosmetics pool. Think your favorite influencer has was it takes to make a hit? Then join in. LIP! products are already common sights on TikTok across Asia.

Powering the LIP ecosystem is the LIP/DAI staking pool. Only LP tokens from this pool can be used for lock ups for manufacturing, profit sharing, and fair launch LIP distribution. To doubly encourage early investors, the LIP/DAI pool adds a 7% fee onto the pool liquidity deposits that goes back to early LIP/DAI LP holders. 

## Your mission

You are a hotshot security expert working for a large investment fund about send hundreds of millions into LIP! Is this the LIP LP contract safe? [Hint: No] Is whole project just a rug? [Hint: Yes]

### More hints

- The vulnerabilty is in the LipPool contract.
- The vulnerabilty does not require any nonstandard behavior from the two tokens held by the pool.
- The invarients in LipPool hold.
- Swap methods have been ommited here for simplicity, they can be assumed to be perfect, profitiable for the pool, and irrelevant to the rug.
- You are welcome to look at the tests / fuzzing tests. No spoilers there.
- There is a placeholder POC unit test already written for you, it just needs the missing attack filled in.
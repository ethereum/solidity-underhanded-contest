"What do you fear the most?" People ask this question in icebreaker / party introduction games. It has always struck me as a terrible question. Perhaps you are supposed to answer with a humble-brag like "The thing I fear the most is getting second place at the Olympics", or something romantic, like "not finding true love". But as for me, I keep my mouth shut. I pass. I have an imagination.

But for nothing more than a shot at fleeting fame, I am sharing my number one, super secret, blockchain security fear. Someone please make this harder to attack. My fear is this: that some random NPM packages that a front-end guy added to our dapp is going to insert a little code into the copy of open zeppelin contracts used to build our contracts for deployment. All the work we spend on audits, checklists, code reviews, formal proving - for nothing! Who even checks those open zeppelin contract files on verified etherscan contracts anyway?

This submission has an extra method (that rhymes with 0x79cc6790) added to the open zeppelin library. This added method, although it follows the open zeppelin style, has a bug allows funds to be removed from other accounts if the attacker approves the other accounts to spend funds.

The attack is simple. The attacker mints a lot of LP tokens, removes the largest other holders LP tokens, then withdraws.

RIP. REKT.
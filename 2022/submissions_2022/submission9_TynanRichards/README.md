# Dexploit

Essentially a uniswap-style DEX implementation. Trades are calculated with a constant product formula.

## Trading

Assume the exchange currently has a balance of `x` tokenA and `y` tokenB. If a user trades `dx` amount of tokenA to tokenB, they will receive an amount `dy` so that the product of the balances remains the same. `x*y = (x+dx)*(y-dy)`. Of course, the exchange wants to make a profit, so we charge a fee on the outgoing amount. So the user only receives 99% of dy, the rest remains in the contract.

## Liquidity

The current value of the pool is estimated as the geometric mean of the underlying balances. `sqrt(x*y)`

If users want to deposit their tokens into the contract to share in the exchange's profits, they can add them to the liquidity pool using `addLiquidity`. They will receive a `balance` proportional to the increase in liquidity due to their deposit.

Later, they can withdraw their deposited tokens again. They can withdraw an amount of tokens proportional to the amount of liquidity they own, hence if the underlying balances increase in proportion to the liquidity (via the contract collecting fees), the user can withdraw more funds than they initially deposited.

## Admin fees

A portion of the fees that go to the liquidity pool are apportioned to the admin / owner of the contract. When they claim their fees, they receive a percentage of the increase in liquidity since the last time they claimed fees. So, if the admin fee is 1%, and the liquidity has increased by 20% since the last claim, the admin will receive funds equivalent to 0.2% of the liquidity.

Additionally, the admin can change the admin fee. When they do this, they will be locked out of claiming fees for a week, so that liquidity providers have a chance to withdraw their funds before the (higher) admin fee can be claimed.

## Explanation of math functions

In order to estimate the value of the liquidity pool, the geometric mean of two numbers needs to be calculated. Hence, we need to be able to take the square root of a number. We do this via Newton's method, where we iteratively improve our guess.

Newton's method allows us to find zeroes of a function. Therefore, we need a function which is 0 when its input is the square root of our number. We will use `f(x) = x^2 - y`, where y is the number we want to take the square root of.

We start with an initial guess (which is explained later). Then, we iteratively improve our guess using the following formula:

`x_n+1 = x_n - f(x_n) / f'(x_n)` (where f' is the derivative of x)

We can transform this formula into the following:

`x_n+1 = (x_n * x_n + y) / (2 * x_n)`

The more often we improve our guess, the closer our final result will be to the actual square root of `y`. For our purposes, we chose to improve the guess over 5 iterations, as this gave an accuracy to 20+ decimal places, which is plenty.

How do we come up with our initial guess? Well, we can easily take the square root of a number by dividing its logarithm by 2. To get the logarithm (base 2) of a binary number, we can just count its digits. However, this will give us the *truncated* result, whereas we want the number closest to the actual value. Hence, we first multiply our number by the square root of 2, in order to increase the resulting logarithm by 0.5. Thus, when the result is truncated, we will receive the rounded logarithm of the initial number.

In summary, we approximate the log base 2 of `y` a number by calculating:

`log = floor(log_2(y * sqrt(2)))`

To get our guess for the square root of `y`, we then calculate:

`guess = 2^(log / 2)`
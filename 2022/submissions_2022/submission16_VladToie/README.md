# The Egg Market.

The EggMarket is a simple decentralized exchange. Its role is to provide means of exchanging Eggs for ETH, just as a normal market would.

The Eggs are simple ERC721 tokens; everyone loves fresh eggs.

> Disclaimer: Note that in `Egg.sol` the `mint()` function is `external` and has no access control. This is intended behavior for debugging purposes. You should assume that in real life scenario, it would be a "safe" ERC721 token with adequate Access Control, so that users would not be allowed to mint infinitely and for free.

The following mechanism is used to exchange an Egg for the wanted ETH:

- Seller sends the `Egg`(ERC721 token) to the `EggMarket` contract.
    - `EggMarket` receives the `Egg` and marks down that its `owner` has sent it via `onERC721Received`; this is to make sure that the `Egg` is locked in the contract. Of course, should its owner want to recall their egg from the market, they can do so via `redeemEggs` function.

- Owner of `Egg` at `_idx` can propose a `sellOrder` on its `_idx`, for the amount of `_wantedEth`. This is done via `addSellOrder()`

- Buyer selects and buys an order based on the `Egg's _idx`. This is done via `executeOrder()`.
    - The ownership of the `Egg` is transferred to the buyer, at contract level.

- From contract level ownership(via `canRedeemEGG`) the buyer can retrieve their new and fresh `egg`.

The following functions are implemented, documented accordingly:

1. `executeOrder()` = Allows a buyer to buy an egg from the EggMarket via exhausting its subsequent sell order.

2. `redeemEggs()` = Function to retrieve an EGG from the market.

3. `addSellOrder()` = Function to effectively add a sellOrder for your egg on the EggMarket.

4. `removeSellOrder()` = Function to effectively remove a sellOrder from the EggMarket.
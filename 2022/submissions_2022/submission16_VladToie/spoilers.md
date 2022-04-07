# The Rotten Egg Market.

> The Eggs are simple ERC721 tokens; everyone loves fresh eggs. Nobody loves Rotten Eggs though... 

The intended vulnerability here is the fact that there is no check on whether the received ERC721 token is an `Egg`; it can be a malicious `"Rotten"` egg, for that matter, let me explain how:

- An attacker deploys a `RottenEgg` contract, identical structure(an ERC721 token) as the `Egg`.

- Having unlimited access to the `minting` of the `RottenEggs` the attacker can virtually obtain any `tokenIdx`.

- Note that the `onERC721Received` does not check what type of token is received. It just marks its `tokenIdx` owner as the `owner` of the transfer at hand.

- In the scenario where a legitimate `Egg` seller has provided a legitimate `Egg`, the attacker can overwrite the `Egg` ownership via transferring a `RottenEgg`, hence stealing any `Egg` that are locked in the contract.

> Bonus : if the user transfers their `Egg` via ERC721's `transferFrom` the `onERC721Received`  does not trigger, essentially locking the `Egg` in the `EggMarket`, since it would not be mapped to its sender; in this scenario anyone can trigger the aformentioned exploit and steal this locked `Egg`. More on why `safeTransferFrom()` is needed to trigger the [`onERC721Received` read this post](https://forum.openzeppelin.com/t/erc721holder-ierc721receiver-and-onerc721received/11828).
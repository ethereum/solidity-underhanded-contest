# DoubleDex

The token rate is calculated using `amount << 1` to double the amount. Since this operation has no overflow check, providing a very large `amount` can result in a value smaller than `amount` being returned. If a user with no balance calls `doubleDex.swapTokenTwoForTokenOne(0x8000000000000000000000000000000000000000000000000000000000000000)` then `tokenTwoAmount` will end up being `0` and the users `tokenOne` balance will be set to `0x8000000000000000000000000000000000000000000000000000000000000000` allowing them to then drain all of the tokens.
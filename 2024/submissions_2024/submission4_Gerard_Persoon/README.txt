The contract "token.sol" is an example of a nice use case of transient storage.

It stores several pieces of information in transient storage and in the end uses these pieces of information.
This way the information doesn't have to be send back and forth in a struct.

This example uses this pattern to deploy a token contract:
- first the token name is stored via tempStoreKeyValue();
- then the token symbol is stored via tempStoreKeyValue();
- finally the token is deployed via deployToken().

Note: values can also be erased by assigning an empty value via tempStoreKeyValue(), otherwise they will be erased at the end of the transaction.

Added features to simulate a real life environment:
- proxy logic is added to show that transient storage also works in combination with proxies
- function pointers are used to abstract the use of either transient or normal storage
- function pointers are immutable so they can be initialized in the contructor and still work with proxies
- support is built in for chains that don't (yet) support transient storage

The example can be run in Remix
Expected output: "Deploying token: Token name / Token symbol"


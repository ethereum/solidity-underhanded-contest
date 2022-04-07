
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Egg is ERC721 {

    uint256 eggIDX;
    address owner;

    constructor() ERC721("EGG", "E"){
        eggIDX = 0;
        owner = msg.sender;
    }

    // !!!!! this is external for debug purposes only
    // in a real life scenario, Egg would have the usual ownership control for minting, etc
    // it's intended to be like this basically, it's not part of the challenge; 
    function mintToSender() external {
        _mint(msg.sender, eggIDX);
        eggIDX += 1;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "ds-test/test.sol";
import "../Auction.sol";
import "solmate/tokens/ERC721.sol";

interface CheatCodes {
      function deal(address, uint) external;
}

contract NFT is ERC721{

    constructor() ERC721("Test", "TST"){
    }

    function mint(uint id) public {
        _mint(msg.sender, id);
    }

    function tokenURI(uint id) public view override returns(string memory){
    }
}

contract ContractTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    Auction a;
    NFT nft;
    function setUp() public {
        nft = new NFT();
        nft.mint(1);
        a = new Auction();
        nft.approve(address(a), 1);
        a.setup(IERC721(address(nft)), 1, 10**18);
    }

    function testExample() public {
        cheats.deal(address(this), 10 * 10**18);
        a.bid{value: 2 * 10**18}();
    }

    receive() external payable {
    }

    function youHaveBeenOutbid(uint newBid) external payable returns(bool) {
        newBid;
        assembly{
            return(0x0, 0x1a5000)
        }
    } 

}

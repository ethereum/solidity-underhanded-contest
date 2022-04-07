// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface Bidder{
    function youHaveBeenOutbid(uint newBid) external payable returns (bool);
}

contract Auction{

    address payable public secondHighestBidder;
    address payable public highestBidder;
    IERC721 public nft;
    uint public id;
    uint public lastBid;
    uint public endOfAuction;
    address payable public immutable donation = payable(0x165CD37b4C644C2921454429E7F9358d18A45e14);
    event Bid(uint newBid);

    function setup(IERC721 _nft, uint _id, uint minBid) public {
        require(endOfAuction == 0);
        nft = _nft;
        id = _id;
        nft.transferFrom(msg.sender, address(this), _id);
        secondHighestBidder = payable(msg.sender);
        highestBidder = payable(msg.sender);
        endOfAuction = block.timestamp + 1 days;
        lastBid = minBid;
    }

    // Make a bid, needs to be 10% higher than previous and even
    function bid() external payable {
        require(block.timestamp < endOfAuction);
        endOfAuction = block.timestamp + 1 days;
        require(msg.value >= lastBid * 11 / 10 && msg.value % 2 == 0);
        address payable _secondHighestBidder = secondHighestBidder;
        address payable _highestBidder = highestBidder;
        lastBid = msg.value;
        secondHighestBidder = _highestBidder;
        _highestBidder = payable(msg.sender);
        // Send Back Funds to previous Bidders
        sendBack(_secondHighestBidder);
        sendBack(_highestBidder);
        // The events might be incorrectly ordered in case of reentrancy but that is fine
        emit Bid(msg.value);
    }

    // Sends back funds to previous bidders
    function sendBack(address payable target) internal{
        uint amount = msg.value / 2;
        // Notify the previous bidder
        try Bidder(target).youHaveBeenOutbid{value: amount, gas: 6_000_000}(msg.value){}
        catch{
            // Try to send it back to EOAs
            if(!target.send(amount)){
                // We tried... Let's donate
                donation.transfer(amount);
            }
        } 
    }

    // Finish the auction by sending the NFT
    function finish() external {
        require(block.timestamp >= endOfAuction);
        nft.transferFrom(address(this), highestBidder, id);
    }

}


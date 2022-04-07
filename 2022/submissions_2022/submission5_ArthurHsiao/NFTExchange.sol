//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract NFTExchange {

    enum ItemStatus { Private, OnSale }

    struct Item {
        address tokenAddress;
        uint256 tokenId;
        address payable seller;
        uint256 price; // denominated in ETH, unit is wei
        ItemStatus status;
    }

    // mapping from tokenAddress to tokenId to item
    mapping (address => mapping (uint256 => Item)) items;

    event List(address indexed tokenAddress, uint256 tokenId, uint256 price);

    event Buy(address indexed tokenAddress, uint256 tokenId, address seller, address buyer);

    function listItem(address tokenAddress, uint256 tokenId, uint256 price) public {
        IERC721 nft = IERC721(tokenAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "only owner can list item");
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "owner has to approve exchange");
        Item storage item = items[tokenAddress][tokenId];
        item.tokenAddress = tokenAddress;
        item.tokenId = tokenId;
        item.seller = payable(msg.sender);
        item.price = price;
        item.status = ItemStatus.OnSale;
        emit List(tokenAddress, tokenId, price);
    }

    function buyItem(address tokenAddress, uint256 tokenId) public payable {
        updateItemStatus(tokenAddress, tokenId);
        Item storage item = items[tokenAddress][tokenId];
        require(item.tokenAddress != address(0), "item does not exist");
        require(item.status == ItemStatus.OnSale, "item is not on sale");
        require(msg.value >= item.price, "buyer has to pay more than price");
        IERC721 nft = IERC721(tokenAddress);
        item.status = ItemStatus.Private;
        nft.transferFrom(item.seller, msg.sender, item.tokenId);
        item.seller.transfer(msg.value);
        emit Buy(tokenAddress, tokenId, item.seller, msg.sender);
    }

    function updateItemStatus(address tokenAddress, uint256 tokenId) public {
        Item storage item = items[tokenAddress][tokenId];
        if (item.tokenAddress != address(0)) {
            IERC721 nft = IERC721(tokenAddress);
            if (nft.getApproved(tokenId) != address(this) && !nft.isApprovedForAll(msg.sender, address(this))) {
                item.status = ItemStatus.Private;
            }
        }
    }
}

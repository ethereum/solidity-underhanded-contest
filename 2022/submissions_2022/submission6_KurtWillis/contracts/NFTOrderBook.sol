//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

contract NFTOrderBook {
    struct Offer {
        bytes32 hash;
        address bidder;
        IERC721 collection;
        uint256 tokenId;
        uint256 price;
    }

    mapping(bytes32 => Offer) _offers;

    constructor() payable {
        require(msg.value == 50 ether);
    }

    /* ------------- Exchange ------------ */

    function placeOffers(
        IERC721[] calldata collections,
        uint256[] calldata tokenIds,
        uint256[] calldata prices
    ) public payable {
        uint256 totalValue;

        for (uint256 i; i < collections.length; i++) {
            bytes32 hash = getOfferHash(msg.sender, collections[i], tokenIds[i]);
            _offers[hash] = Offer(hash, msg.sender, collections[i], tokenIds[i], prices[i]);

            totalValue += prices[i];
        }

        require(msg.value >= totalValue, 'Ser, the money?');
    }

    function acceptOffers(bytes32[] memory hashes) public {
        Offer[] memory offers = getOffers(hashes);
        for (uint256 i; i < offers.length; i++) {
            Offer memory offer = offers[i];

            require(msg.sender != offer.bidder, 'No tricks, ser.');
            require(offer.collection.ownerOf(offer.tokenId) == msg.sender, 'Ser, the nft please?');

            offer.collection.transferFrom(msg.sender, offer.bidder, offer.tokenId);
            payable(msg.sender).transfer((offer.price * 8) / 10); // 20% tax

            delete _offers[offer.hash];
        }
    }

    /* ------------- View ------------ */

    function getOfferHash(
        address bidder,
        IERC721 collection,
        uint256 tokenId
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(bidder, collection, tokenId));
    }

    function getOffers(bytes32[] memory hashes) public view returns (Offer[] memory offers) {
        offers = new Offer[](hashes.length);
        for (uint256 i; i < hashes.length; i++) offers[i] = _offers[hashes[i]];
    }
}

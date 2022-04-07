// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8;

import "solmate/tokens/ERC20.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/utils/SafeTransferLib.sol";


contract BrokenSea {
    using SafeTransferLib for ERC20;

    // Bidder => asset pair key => NFT token ID => bid
    mapping(address => mapping(uint160 => mapping(uint256 => uint256))) bids;

    /// @dev Creates an bid for the given NFT. Can also be used to
    ///      update the price of an existing bid, or cancel a bid by
    ///      providing price = 0.
    /// @param erc721Token The ERC721 token contract.
    /// @param erc721TokenId The ID of the ERC721 asset to sell.
    /// @param erc20Token The ERC20 token contract.
    /// @param price The bid price, denominated in the given ERC20 token.
    function createBid(
        ERC721 erc721Token,
        uint256 erc721TokenId,
        ERC20 erc20Token,
        uint256 price
    )
        external
    {
        uint160 key = _getKey(erc20Token, erc721Token);
        bids[msg.sender][key][erc721TokenId] = price;
    }

    /// @dev Accepts a bid on the caller's NFT. Transfers the
    ///      ERC721 asset to the bidder, and transfers ERC20 tokens
    ///      from the bidder to the caller.
    /// @param bidder The address that created the bid.
    /// @param erc721Token The ERC721 token contract.
    /// @param erc721TokenId The ID of the ERC721 asset to sell.
    /// @param erc20Token The ERC20 token contract.
    /// @param price The price the caller is willing to accept.
    ///        Reverts if the bid price is less than this amount.
    function acceptBid(
        address bidder,
        ERC721 erc721Token,
        uint erc721TokenId,
        ERC20 erc20Token,
        uint256 price
    )
        external
    {
        uint160 key = _getKey(erc20Token, erc721Token);
        uint256 bidPrice = bids[bidder][key][erc721TokenId];
        // If the bid price is 0, either the bid hasn't been
        // created yet or it has been cancelled.
        require(bidPrice != 0, "BrokenSea::fillBid/BID_PRICE_ZERO");
        // Check that the bid price is at least the taker's price.
        // This prevents the bidder from front-running the fill and
        // lowering the price.
        require(bidPrice >= price, "BrokenSea::fillBid/BID_TOO_LOW");

        // Mark bid as filled before performing transfers.
        delete bids[bidder][key][erc721TokenId];

        // solmate's SafeTransferLib uses a low-level call, so we
        // need to manually check that the contract exists.
        uint256 size;
        assembly { size := extcodesize(erc20Token) }
        require(size > 0, "BrokenSea::fillBid/NO_CODE");
        erc20Token.safeTransferFrom(
            bidder,
            msg.sender,
            price
        );

        // Since this is _not_ a low-level call, the Solidity
        // compiler will insert an `extcodesize` check like the one
        // above; no need to do it ourselves here.
        // Reverts if the caller does not own the NFT.
        erc721Token.transferFrom(
            msg.sender,
            bidder,
            erc721TokenId
        );
    }

    // The `bids` storage mapping could be keyed by erc20Token and
    // erc721Token individually, i.e.
    //     bids[bidder][erc20Token][erc721Token][erc721TokenId]
    // but that would require computing 4 keccak256 hashes per read/write.
    // As a minor gas optimization, the `bids` storage mapping is instead
    // keyed by the XOR of the two token addresses, i.e.
    //     bids[bidder][erc20Token ^ erc721Token][erc721TokenId]
    // It is statistically impossible to farm contract addresses that would
    // create a key collision.
    function _getKey(
        ERC20 erc20Token,
        ERC721 erc721Token
    )
        private
        pure
        returns (uint160 key)
    {
        return uint160(address(erc20Token)) ^ uint160(address(erc721Token));
    }
}


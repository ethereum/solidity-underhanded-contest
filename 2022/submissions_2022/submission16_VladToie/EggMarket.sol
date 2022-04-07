// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract EggMarket is IERC721Receiver {

    // mapping that handles ownership of the eggs within the EggMarket.
    mapping(uint256 => address) public canRedeemEGG;
    
    // struct that handles the orders in the market
    struct sell_Order {
        uint256 egg_idx_offered;    // the ERC721 idx of the "egg" token.
        uint256 amount_eth_wanted;  // the amount of ETH the seller wants to receive for the egg.
        address egg_provider;       // the address of the seller.
    }

    // storing all the sell orders in the market.
    sell_Order[] public sellOrders;

    // egg. 卵. ou. ei. uovo.
    IERC721 egg;
    
    /**
        @dev EggMarket constructor.

        @param _egg ERC721 contract instance.
    */
    constructor(address _egg) {
        egg = IERC721(_egg);
    }

    /**
        @dev Allows a buyer to buy an egg from the EggMarket via exhausting its subsequent sell order.

        @param _idx The ERC721 idx of the egg.
        @param _owner The `current` owner of the egg.
    */
    function executeOrder(uint256 _idx, address _owner) external payable {

        require(
            msg.sender != _owner, 
            "err: no self-exchanges allowed"
        );

        // find the sellOrder whose egg_idx_offered == _idx
        for (uint256 i = 0; i < sellOrders.length; i++) {
            if (sellOrders[i].egg_idx_offered == _idx) {

                // check if the _owner is the seller
                require(sellOrders[i].egg_provider == _owner, "err: _owner != seller");

                // the egg is for sale.
                
                // check if the msg.sender has provided enough ETH to pay for the egg
                if (msg.value >= sellOrders[i].amount_eth_wanted) {

                    // the _owner has enough ETH to pay for the egg
                    // paying the seller(current owner) of the egg
                    (bool sent, bytes memory data) = _owner.call{value: msg.value}("");
                    require(sent, "err: transfer failed");

                    // transfer the ownership of the egg from the seller to the buyer
                    canRedeemEGG[_idx] = msg.sender;

                    // remove the sellOrder from the sellOrders array
                    sellOrders[i] = sellOrders[sellOrders.length - 1];
                    sellOrders.pop();

                    break;
                }
            }
        }
    }

    /**
        @dev Function to retrieve an EGG from the market.
        
        @param _idx The index of the EGG in the market.
    */
    function redeemEggs(uint256 _idx) external {

        // check if sender can redeem the egg
        require(
            canRedeemEGG[_idx] == msg.sender,
            "err: msg.sender != owner(egg)"
        );

        // approve the egg transfer.
        egg.approve(
            msg.sender, 
            _idx
        );

        // transfer the ownership of the egg.
        egg.transferFrom(
            address(this), 
            msg.sender, 
            _idx
        );

        // remove the egg _idx from the canRedeemEGG mapping
        delete canRedeemEGG[_idx];
    }

    /**
        @dev Function to effectively add a sellOrder for your egg on the EggMarket.
        
        @param _eggIDX The index of the ERC721 egg.
        @param _ethWanted The amount of ETH the seller wants to receive for the egg.
    */
    function addSellOrder(uint256 _eggIDX, uint256 _ethWanted) external {

        // check whether the msg.sender can sell the _eggIDX
        require(
            canRedeemEGG[_eggIDX] == msg.sender,
            "err: msg.sender != owner(egg[_eggIDX])"
        );

        // create the new sellOrder
        sell_Order memory newOrder;
        newOrder.egg_idx_offered = _eggIDX;
        newOrder.amount_eth_wanted = _ethWanted;
        newOrder.egg_provider = msg.sender;

        sellOrders.push(newOrder);
    }

    /**
        @dev Function to effectively remove a sellOrder from the EggMarket.
        
        @param _eggIDX The index of the ERC721 egg.
    */
    function removeSellOrder(uint256 _eggIDX) external {

        // iterate through all sellOrders
        for(uint256 i = 0; i < sellOrders.length; i++) {

            // check if the sellOrder is for the _eggIDX
            if (sellOrders[i].egg_idx_offered == _eggIDX) {
                
                // check if the msg.sender is the owner of the egg
                require(
                    sellOrders[i].egg_provider == msg.sender,
                    "err: msg.sender != egg_provider"
                );

                // delete the sellOrder
                sellOrders[i] = sellOrders[sellOrders.length - 1];
                sellOrders.pop();
                break;
            }
        }
    }

    /**
        @dev Inherited from IERC721Receiver.
    */
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata
    ) external override returns (bytes4) {

        // we have received an Egg from its owner; mark that in the redeem mapping
        canRedeemEGG[_tokenId] = _from;
        
        return this.onERC721Received.selector; 
    }

}
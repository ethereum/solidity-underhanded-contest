// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CheapMarketplace {

    struct SignedOrder {
        bool isBuy;
        address maker;
        uint256 tokenID;
        uint256 price;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    ERC20 public immutable paymentToken;
    ERC721 public immutable nft;
    mapping(bytes32 => bool) public voidOrders;

    constructor(ERC20 _paymentToken, ERC721 _nft){
        paymentToken = _paymentToken;
        nft = _nft;
    }

    function _getOrderID(SignedOrder memory order) internal pure returns (bytes32){
        return keccak256(abi.encode(
            order.isBuy, order.maker, order.tokenID, order.price, order.v, order.r, order.s
        ));
    }

    function _validateOrder(bytes32 hash, SignedOrder memory order) internal view returns (bool) {
        /* Order must have not been canceled or already filled. */
        bytes32 orderID = _getOrderID(order);
        if (voidOrders[orderID]) {
            return false;
        }
        return ecrecover(hash, order.v, order.r, order.s) == order.maker;
    }

    function orderMessage(
        bool isBuy, 
        address maker, 
        uint256 tokenID, 
        uint256 price
    ) public pure returns(bytes32) {
        return keccak256(abi.encode(
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encode(isBuy, maker, tokenID, price))
        ));
    }

    function _requireValidOrder(SignedOrder memory order) internal view {
        bytes32 hash = orderMessage(order.isBuy, order.maker, order.tokenID, order.price);
        require(_validateOrder(hash, order));
    }

    function _cancelOrder(SignedOrder memory order) internal {
        /* Check order is valid */
        _requireValidOrder(order);

        /* Assert sender is authorized to cancel order. */
        require(msg.sender == order.maker);
        
        /* Mark order as cancelled, preventing it from being matched. */
        voidOrders[_getOrderID(order)] = true;
    }

    function cancelOrder(
        bool isBuy,
        address maker,
        uint256 tokenID,
        uint256 price,
        bytes32[3] calldata vrs
    ) external {
        uint8 v = uint8(uint256(vrs[0]));
        SignedOrder memory order = SignedOrder(isBuy, maker, tokenID, price, v, vrs[1], vrs[2]);
        _cancelOrder(order);
    }

    function _atomicMatch(SignedOrder memory buyOrder, SignedOrder memory sellOrder) internal {
        /* Check orders are valid */
        _requireValidOrder(buyOrder);
        _requireValidOrder(sellOrder);

        require(
            buyOrder.isBuy && !sellOrder.isBuy
            && buyOrder.price >= sellOrder.price
        );
       
        /* Mark orders as void, preventing them from being matched. */
        voidOrders[_getOrderID(buyOrder)] = true;
        voidOrders[_getOrderID(sellOrder)] = true;

        /* Exchange assets */
        nft.transferFrom(sellOrder.maker, buyOrder.maker, buyOrder.tokenID);
        paymentToken.transferFrom(buyOrder.maker, sellOrder.maker, buyOrder.price);
    }

    function atomicMatch(
        uint256 tokenID,
        address buyMaker,
        uint256 buyPrice,
        bytes32[3] calldata vrsBuy,
        address sellMaker,
        uint256 sellPrice,
        bytes32[3] calldata vrsSell
    ) external {
        uint8 vBuy = uint8(uint256(vrsBuy[0]));
        uint8 vSell = uint8(uint256(vrsSell[0]));
        SignedOrder memory buyOrder = SignedOrder(
            true, buyMaker, tokenID, buyPrice, vBuy, vrsBuy[1], vrsBuy[2]
        );
        SignedOrder memory sellOrder = SignedOrder(
            false, sellMaker, tokenID, sellPrice, vSell, vrsSell[1], vrsSell[2]
        );
        _atomicMatch(buyOrder, sellOrder);
    }
}
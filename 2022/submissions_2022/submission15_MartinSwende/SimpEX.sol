// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "AssetManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpEX{
    // the orderbook
    mapping (bytes32 => Order) public orderbook;
    // native token tracking, for making/taking orders
    mapping (address => uint256) public balances;
    // The asset manager, set at construction time
    address assetMgr;

    constructor(address assets){
        assetMgr = assets;
    }

    struct Order{
        uint cost;      // denominated in to-amount: 32 bytes -> 256 bits, e.g. 
        address origin; // address of market maker
        uint amount;    // amount of units 
        bool direction; // sell or buy-side
        string assetid;  // asset id, e.g. "TETH/BNB"
    }

    // make() is the market-make function, placing an order into the orderbok
    function make(uint cost, uint amount, bool direction, string calldata assetPair) public{        
        // Putting an order in costs 1 token
        require(balances[msg.sender] > 0,"balance too low");
        balances[msg.sender]--;
        // check that the asset is defined
        (bool ok,,) = AssetMgr(assetMgr).getAsset(assetPair);
        require(ok, "inactive/undefined asset pair");

        // Place it in the order book
        Order memory o = Order({ cost: cost, origin: msg.sender, amount:amount, direction:direction, assetid: assetPair});
        bytes32 id = keccak256(abi.encode(o.cost, o.origin, o.amount, o.direction, o.assetid));
        orderbook[id] = o;
        // Todo: fire an event - omitted for brevity
    }

    // take is the function to take an order from the orderbook.
    function take(bytes32 id) public{
        // Taking an order costs 1 token
        require(balances[msg.sender] > 0,"insufficient balance");
        balances[msg.sender]--; 
        Order memory order = orderbook[id];
        delete orderbook[id]; // Update state before external calls
        require(order.origin != address(0), "order does not exist") ;

        (bool ok, address alpha, address beta) = AssetMgr(assetMgr).getAsset(order.assetid);
        require(ok, "asset pair cancelled/halted");

        address seller;
        address buyer;
        if (order.direction){
            seller = msg.sender;
            buyer = order.origin;
        }else{
            buyer = msg.sender;
            seller = order.origin;
        }
       
        // seller -> buyer 100 TKN1
        IERC20(alpha).transferFrom(seller, buyer, order.amount);
        // buyer -> seller 100 TKN2
        IERC20(beta).transferFrom(buyer, seller, order.cost);
    }
    // Omitted for brevity: 
    // 
    // buyToken(...) payable  - buys a native token for trading
    // cancelOrder(bytes32 id)  - removes an order from the orderbook
    // collect() -- ships accumulated ether to the deployer 
}

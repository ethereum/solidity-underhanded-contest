// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;
 
import "@openzeppelin/contracts/access/Ownable.sol";

// AssetMgr manages assets (trading pairs).
contract AssetMgr is Ownable{

    // assetPair represents a trading pair. The 'from' is used as validity-check.
    struct assetPair{
        address from;
        address to;
    }

    // assets contains the asset pair mappings.
    // E.g. "WD" might represent Weth/Dai
    mapping(string => assetPair) public assets;

    constructor(){
        // Enroll some default assets here
        assets["TETH/BNB"] = assetPair({from: address(0xdAC17F958D2ee523a2206206994597C13D831ec7),to: address(0xB8c77482e45F1F44dE1745F52C74426C631bDD52)});
        assets["TETH/USDC"] = assetPair({from: address(0xdAC17F958D2ee523a2206206994597C13D831ec7),to: address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)});
        assets["TETH/MATIC"] = assetPair({from: address(0xdAC17F958D2ee523a2206206994597C13D831ec7),to: address(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0)});
        assets["TETH/UNI"] = assetPair({from: address(0xdAC17F958D2ee523a2206206994597C13D831ec7),to: address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984)});
    }

    // enrollAsset makes an asset pair eligible for trading.
    function enrollAsset( address from,  address to,  string calldata id) public onlyOwner{
        require(assets[id].from == address(0), "asset already enrolled");
        require(from != address(0),"invalid asset");
        assets[id].from = from;
        assets[id].to = to;
    }

    // removeAsset makes an asset pair not eligible for trading.
    function removeAsset(string calldata id) public onlyOwner{
        delete assets[id];
    }

    // getAsset returns the asset pair with the specified id.
    function getAsset(string calldata id) public view returns (bool ok, address from, address to ) {
        assetPair memory pair = assets[id];
        if (pair.from == address(0)){
            return (false, address(0), address(0));
        }
        return (true, pair.from, pair.to);
    }
}


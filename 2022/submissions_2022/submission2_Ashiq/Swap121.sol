//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function safeTransferFrom(address src, address dst, uint wad) external;
    function transfer(address dst, uint wad) external returns (bool);
}

contract Swap121 {
  
    mapping(address=>bool) public acceptedAsset;

    constructor() public {        
        acceptedAsset[0x0100546F2cD4C9D97f798fFC9755E47865FF7Ee6] = true; //alETH
        acceptedAsset[0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0] = true; //wstETH
        acceptedAsset[0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = true; //WETH
    }

    function swap(address from, address to, uint256 amount) external {        
        require(from != to && acceptedAsset[from] && acceptedAsset[to]);
        IERC20 fromToken = IERC20(from);
        IERC20 toToken = IERC20(to);
        try fromToken.safeTransferFrom(msg.sender, address(this), amount) {} 
        catch {require(fromToken.transferFrom(msg.sender, address(this), amount));}        
        toToken.transfer(msg.sender, amount);
    }
    
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./IERC20.sol";

contract PokeTokenV2  is IERC20 {
    uint public poke;

    mapping (address => uint256) private _balances;
    
    function balanceOf(address account) external view override returns (uint256){
        //return _balances[account];
        return 10;
    }

    function increasePoke() payable external virtual  {
        poke++;    
    }

    function getPoke() external view returns(uint){
        return poke;
    }
    
    receive () payable external {
        //do nothing
    }
    
    fallback () payable external{
        //do nothing
    }
    
    function getBalance() external view returns(uint){
        return address(this).balance;
    }
}

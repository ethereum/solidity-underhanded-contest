// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "http://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.1-solc-0.7/contracts/token/ERC20/ERC20.sol";
import "./Proxy.sol";

contract TestERC20 is ERC20 {
    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public stakingTime;
    mapping(address => uint256) public blockedUntil;
    
    constructor(address custodian) ERC20('Upgradable','UPG') {
        _mint(custodian, 1000 ether); // sell/distribute somehow
    }
    
    function _beforeTokenTransfer(address from, address, uint256) internal view override {
        require(blockedUntil[from] == 0 || block.timestamp > blockedUntil[from] , 'Tokens blocked');
    }
    
    function stakeForVoting() external {
        require(stakedAmount[msg.sender] == 0, 'Already staking');

        stakedAmount[msg.sender] = balanceOf(msg.sender);
        stakingTime[msg.sender] = block.timestamp;
    
        _burn(msg.sender, balanceOf(msg.sender));
    }

    function unstake() external {
        _mint(msg.sender, stakedAmount[msg.sender]);

        stakedAmount[msg.sender] = 0;
        stakingTime[msg.sender] = 0;
        blockedUntil[msg.sender] = block.timestamp + 100;
    }
}
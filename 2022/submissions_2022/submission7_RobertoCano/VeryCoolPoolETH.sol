//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface ThirdPartyETHPool {
    function stake() external payable;

    function withdraw(uint256 amount) external;
}

interface IVeryCoolPoolETH {
    function withdraw(address payable from, address staker) external;
}

contract VeryCoolPoolETH is Ownable {
    using Address for address payable;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public withdrawalEndTs;

    function getEncodedData(bool longStake) external pure returns (bytes memory) {
        return abi.encode(longStake);
    }

    function deposit(
        address from,
        uint256 endTimestamp,
        address staker
    ) external payable onlyOwner {
        require(endTimestamp >= block.timestamp, "End timestamp is in the past");
        require(endTimestamp >= withdrawalEndTs[from], "End timestamp is before previous withdrawal");
        require(msg.value > 0, "No ETH sent for deposit");

        balanceOf[from] += msg.value;
        withdrawalEndTs[from] = endTimestamp;

        ThirdPartyETHPool(staker).stake{ value: msg.value }();
    }

    function withdraw(address payable from, address staker) external onlyOwner {
        uint256 amount = balanceOf[from];

        require(amount > 0, "No ETH to withdraw");
        require(withdrawalEndTs[from] <= block.timestamp, "Cannot withdraw before end of staking period");

        // Original stake + rewards is returned from the third-party
        ThirdPartyETHPool(staker).withdraw(amount);
        from.sendValue(amount);
    }
}

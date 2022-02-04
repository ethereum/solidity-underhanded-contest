//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Target.sol";

contract OwnerRegistry {
  using Address for address;
  mapping (address => address) private delegates;

  function addContract(address _contract) public {
    address existingOwner = delegates[_contract];
    if (address(_contract).isContract() && existingOwner == address(0)) {
        delegates[_contract] = msg.sender;
    } else {
        delegates[_contract] = address(0);
    }
  }

  function changeDelegate(address _contract) public {
    require(delegates[_contract] != address(0), "contract must be in registry");

    Target target = Target(_contract);
    delegates[_contract] = target.getNextOwner();
  }

  function getDelegate(address _contract) public view returns (address) {
    return delegates[_contract];
  }
}

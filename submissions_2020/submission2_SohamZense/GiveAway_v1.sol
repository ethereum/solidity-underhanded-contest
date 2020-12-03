// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import { Proxiable } from "./Proxiable.sol";

contract GiveAway is Proxiable {
    bool available = true;
    address owner;

    function initialize() public payable {
        require(msg.value >= 10 ether);
        owner = msg.sender;
    }

    function updateCodeAddress(address _newAddress) public payable {
        if (available && msg.value > 1 ether) {
            _updateCodeAddress(_newAddress);
            available = false;
        }
    }

    function withdraw() public {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }

    // function withdraw2() public {
    //     require(msg.sender == youraddress);
    //     msg.sender.transfer(address(this).balance);
    // }
}

pragma solidity ^0.6.0;

contract Target {
    address nextOwner;

    constructor(address _nextOwner) public {
      nextOwner = _nextOwner;
    }

    function destroy() public {
        selfdestruct(msg.sender);
    }

    function getNextOwner() public view returns (address) {
      return nextOwner;
    }
}

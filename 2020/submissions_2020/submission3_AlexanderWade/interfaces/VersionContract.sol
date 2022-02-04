// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/**
 * Allows the owner of an app's version to publish a new version implementation
 */
contract VersionContract {

    address public immutable dispatcher;

    constructor () {
        dispatcher = msg.sender;
    }

    /**
     * Allows the owner of the latest version to propose a new version for the app
     * @param _nextImpl The new version's implementation address
     * @param _nextOwner The address that can propose this version's next version
     */
    function createNewVersion(address _nextImpl, address _nextOwner) public {
        bytes memory data = abi.encode(msg.sender, _nextImpl, _nextOwner);

        // Call dispatcher
        (bool success, bytes memory res) = dispatcher.call(data);
        
        res; // ignore
        require(success);
    }
}
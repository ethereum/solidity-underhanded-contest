// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/**
 * Allows users to explicitly opt in and out of upgrades in the Dispatcher
 */
contract OptInContract {

    address public immutable dispatcher;

    constructor () {
        dispatcher = msg.sender;
    }

    /**
     * Approve a newer version on behalf of the user
     */
    function optIn(uint _approvedVersion) public {
        bytes memory data = abi.encode(msg.sender, _approvedVersion);

        // Call dispatcher
        (bool success, bytes memory res) = dispatcher.call(data);

        res; // ignore
        require(success);
    }
}
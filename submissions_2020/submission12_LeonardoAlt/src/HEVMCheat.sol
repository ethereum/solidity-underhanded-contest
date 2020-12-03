// SPDX-License-Identifier: GPL-v3

pragma solidity ^0.7.0;

/// HEVM has a special contract able to change the block timestamp.
/// This is used in the tests, to show safe and unsafe upgrades.
contract HEVMCheat {
	address constant hevmCheat = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

	function warp(uint x) public {
		(bool success,) = address(hevmCheat).call(abi.encodeWithSignature("warp(uint256)", x));
		require(success);
	}

	function roll(uint x) public {
		(bool success,) = address(hevmCheat).call(abi.encodeWithSignature("roll(uint256)", x));
		require(success);
	}
}

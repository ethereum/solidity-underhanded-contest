// SPDX-License-Identifier: GPL-v3

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import './DNS.sol';
import './Upgrade.sol';
import './UpgradedDNS.sol';
import './MalDNS.sol';

import './HEVMCheat.sol';
import 'ds-test/test.sol';

contract User {
	IDNS immutable dns;
	Upgrade immutable upgrade;

	constructor(IDNS _dns, Upgrade _upgrade) {
		dns = _dns;
		upgrade = _upgrade;
	}

	function register(string memory _domain, bytes4 _ip) external {
		dns.register(_domain, _ip, address(this));
	}

	function update(string memory _domain, bytes4 _ip) external {
		dns.update(_domain, _ip);
	}

	function updateViaCustomDNS(string memory _domain, bytes4 _ip, IDNS _dns) external {
		_dns.update(_domain, _ip);
	}

	function transfer(string memory _domain, address _owner) external {
		dns.transfer(_domain, _owner);
	}

	function resolve(string memory _domain) external view returns (bytes4, address) {
		return dns.resolve(_domain);
	}

	function optIn() external {
		upgrade.opt(Upgrade.Opt.In);
	}

	function optOut() external {
		upgrade.opt(Upgrade.Opt.Out);
	}
}

contract DNSTest is DSTest {
	HEVMCheat hevm;

	DNS dns;
	UpgradedDNS up_dns;
	UpgradedDNS fake_up_dns;
	MalDNS mal_dns;
	Upgrade upgrade;

	uint constant MAX_USERS = 4;
	User[MAX_USERS] users;

	function setUp() public {
		reset();
	}

	function reset() internal {
		hevm = new HEVMCheat();

		upgrade = new Upgrade();
		dns = new DNS(upgrade);
		up_dns = new UpgradedDNS(dns, upgrade);
		fake_up_dns = new UpgradedDNS(dns, upgrade);
		mal_dns = new MalDNS(0xcafeeeee, dns, upgrade);

		for (uint i = 0; i < MAX_USERS; ++i)
			users[i] = new User(dns, upgrade);
	}

	function test_safe_sequence() public {
		string memory d0 = "a.eth";
		bytes4 i0 = 0x01020304;
		string memory d1 = "b.eth";
		bytes4 i1 = 0x05060708;

		bytes4 ip;
		address owner;

		// User0 registers a.eth
		users[0].register(d0, i0);
		(ip, owner) = dns.resolve(d0);
		assertEq(ip, i0);
		assertEq(owner, address(users[0]));

		// User1 registers b.eth
		users[1].register(d1, i1);
		(ip, owner) = dns.resolve(d1);
		assertEq(ip, i1);
		assertEq(owner, address(users[1]));

		// Admin suggests a new upgrade
		upgrade.newUpgrade(block.timestamp + 60, IDNS(up_dns));
		assertTrue(upgrade.upgradePlanned());

		// User0 opts in
		users[0].optIn();

		// User2 opts in
		users[2].optIn();
		hevm.warp(10);
		// but then gives up
		users[2].optOut();

		// User3 opts in
		users[3].optIn();

		// Time passes, upgrade is now active.
		hevm.warp(70);
		assertTrue(!upgrade.upgradePlanned());

		bool up;
		IDNS to;
		// User0 has an active upgrade
		(up, to) = upgrade.activeUpgrade(address(users[0]));
		assertTrue(up);
		assertEq(address(to), address(up_dns));

		// User1 does not have an active upgrade, never opted in
		(up, to) = upgrade.activeUpgrade(address(users[1]));
		assertTrue(!up);

		// User2 does not have an active upgrade, opted in but then opted out
		(up, to) = upgrade.activeUpgrade(address(users[2]));
		assertTrue(!up);

		// User3 also opted in.
		(up, to) = upgrade.activeUpgrade(address(users[3]));
		assertTrue(up);

		string memory d2 = "c.eth";
		bytes4 i2 = 0x090a0b0c;
		string memory d3 = "d.eth";
		bytes4 i3 = 0x0d0e0f0f;

		// User0 registers c.eth in the upgraded contract
		// Notice that the message is actually relayed from the original
		// to the upgraded DNS.
		users[0].register(d2, i2);
		// Original contract does not have that info
		(ip, owner) = dns.resolve(d2);
		assertEq(ip, 0);
		assertEq(owner, address(0));
		// Upgraded contract has that info
		(ip, owner) = up_dns.resolve(d2);
		assertEq(ip, i2);
		assertEq(owner, address(users[0]));
		// Relayed resolving reads from upgraded contract
		(ip, owner) = users[0].resolve(d2);
		assertEq(ip, i2);
		assertEq(owner, address(users[0]));

		// User0 registers d.eth in the upgraded contract
		users[0].register(d3, i3);
		// Original contract does not have that info
		(ip, owner) = dns.resolve(d3);
		assertEq(ip, 0);
		assertEq(owner, address(0));
		// Upgraded contract has that info
		(ip, owner) = up_dns.resolve(d3);
		assertEq(ip, i3);
		assertEq(owner, address(users[0]));
		// Relayed resolving reads from upgraded contract
		(ip, owner) = users[0].resolve(d3);
		assertEq(ip, i3);
		assertEq(owner, address(users[0]));

		// User1 registers d.eth in the original contract
		users[1].register(d3, i3);
		// Original contract has that info
		(ip, owner) = dns.resolve(d3);
		assertEq(ip, i3);
		assertEq(owner, address(users[1]));
		// No need to relay
		(ip, owner) = users[1].resolve(d3);
		assertEq(ip, i3);
		assertEq(owner, address(users[1]));
		// Upgraded contract has that info, but with a different owner
		(ip, owner) = up_dns.resolve(d3);
		assertEq(ip, i3);
		assertEq(owner, address(users[0]));

		// User0 updates c.eth in the upgraded contract
		bytes4 i2_2 = 0xcafecafe;
		users[0].update(d2, i2_2);
		// Upgraded contract via original contract should resolve
		(ip, owner) = users[0].resolve(d2);
		assertEq(ip, i2_2);
		assertEq(owner, address(users[0]));

		// User0 tries and fails to update c.eth in the upgraded contract
		// via a non opted-in upgrade.
		try users[0].updateViaCustomDNS(d2, 0xcafeaaaa, fake_up_dns) {
			assertTrue(false);
		} catch {
		}

		// User3 registers a.eth in the upgraded contract
		users[3].register(d0, i0);
		(ip, owner) = up_dns.resolve(d0);
		assertEq(ip, i0);
		assertEq(owner, address(users[3]));

		// User0 tries and fails to update a.eth in the upgraded contract
		try users[0].update(d0, 0xaabbccdd) {
			assertTrue(false);
		} catch {
		}

		// All good!
	}

	function test_hack_sequence() public {
		string memory d0 = "a.eth";
		bytes4 i0 = 0x01020304;
		string memory d1 = "b.eth";
		bytes4 i1 = 0x05060708;

		bytes4 ip;
		address owner;

		// User0 registers a.eth
		users[0].register(d0, i0);
		(ip, owner) = dns.resolve(d0);
		assertEq(ip, i0);
		assertEq(owner, address(users[0]));

		// User1 registers b.eth
		users[1].register(d1, i1);
		(ip, owner) = dns.resolve(d1);
		assertEq(ip, i1);
		assertEq(owner, address(users[1]));

		// Admin suggests a new legit upgrade
		upgrade.newUpgrade(block.timestamp + 60, IDNS(up_dns));
		assertTrue(upgrade.upgradePlanned());

		// User0 opts in
		users[0].optIn();

		// User2 opts in
		users[2].optIn();
		hevm.warp(10);
		// but then gives up
		users[2].optOut();

		// User3 also opts in
		users[3].optIn();

		upgrade.cancelUpgrade();
		assertTrue(!upgrade.upgradePlanned());

		// Admin suggests a new malicious upgrade
		upgrade.newUpgrade(block.timestamp + 1, IDNS(mal_dns));
		assertTrue(upgrade.upgradePlanned());

		// Time passes quickly
		hevm.warp(100);
		assertTrue(!upgrade.upgradePlanned());

		mal_dns.backdoor(d0, 0x13371337, address(this));
		(ip, owner) = users[0].resolve(d0);
		assertTrue(ip == 0x13371337);
		assertTrue(owner == address(this));

		// \_O_/
	}
}

// SPDX-License-Identifier: GPL-3
pragma solidity >=0.8.6;

import "ds-test/test.sol";
import "solmate/tokens/ERC20.sol";

import "../MatchMaking.sol";

contract MockToken is ERC20 {
	constructor(
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		uint _amt
	) ERC20(_name, _symbol, _decimals) {
		_mint(msg.sender, _amt);
	}
}

// Mock user for the hack test.
contract User {
	ERC20 token1;
	ERC20 token2;
	MatchMaking mm;

	constructor(ERC20 t1, ERC20 t2, MatchMaking m) {
		token1 = t1;
		token2 = t2;
		mm = m;
	}

	function push(Order memory o) public {
		if (o.kind == Kind.Sell)
			token1.approve(address(mm), o.qtt);
		else
			token2.approve(address(mm), o.qtt);
		mm.push(o);
	}

	function cancelOneSellOrder() public {
		mm.cancelOneSellOrder();
	}

	function cancelOneBuyOrder() public {
		mm.cancelOneBuyOrder();
	}
}

contract MatchMakingTest is DSTest {
	ERC20 token1;
	ERC20 token2;
	MatchMaking mm;

	event O(Order order);

    function setUp() public {
		token1 = new MockToken("A", "A", 18, type(uint).max);
		token2 = new MockToken("B", "B", 18, type(uint).max);
		mm = new MatchMaking(token1, token2);
	}

	function test_match_simple() public {
		uint amt = 100;
		uint price = 10**9;

		token1.approve(address(mm), 10**12);
		token2.approve(address(mm), 10**12);

		mm.push(Order(Kind.Sell, price, amt, address(this)));
		mm.push(Order(Kind.Buy, price, amt, address(this)));

		mm.matchAll();
	}

	function test_match_simple_diff_ratio() public {
		uint amt = 100;
		uint price = 1; // 10^9 token1 = 1 token2

		token1.approve(address(mm), 10**12);
		token2.approve(address(mm), 10**12);

		mm.push(Order(Kind.Sell, price, 10**10+1, address(this)));
		mm.push(Order(Kind.Buy, price, 1, address(this)));

		mm.matchAll();
	}

	function test_match_diff_qtt() public {
		uint amt = 100;
		uint price = 10**9;

		token1.approve(address(mm), 10**12);
		token2.approve(address(mm), 10**12);

		mm.push(Order(Kind.Sell, price, amt, address(this)));
		mm.push(Order(Kind.Sell, price, 1, address(this)));
		mm.push(Order(Kind.Buy, price, amt / 2, address(this)));
		mm.push(Order(Kind.Buy, price, amt / 2, address(this)));
		mm.push(Order(Kind.Buy, price, amt / 2, address(this)));

		mm.matchAll();
	}


	function test_sell() public {
		uint[] memory prices = new uint[](4);
		prices[0] = 100;
		prices[1] = 1; // goes last
		prices[2] = 100_000; // goes first
		prices[3] = 10; // goes in between

		uint amt = 10**9;

		token1.approve(address(mm), amt * prices.length);

		for (uint i = 0; i < prices.length; ++i)
			mm.push(Order(Kind.Sell, prices[i], amt, address(this)));

		for (uint i = 0; i < prices.length; ++i) {
			(Kind kind, uint price, uint qtt, address who) = mm.oSell(i);
			emit O(Order(kind, price, qtt, who));
		}
	}

	function test_buy() public {
		uint[] memory prices = new uint[](4);
		prices[0] = 10;
		prices[1] = 100_000; // goes last
		prices[2] = 1; // goes first
		prices[3] = 100; // goes in between

		uint amt = 100;

		token2.approve(address(mm), amt * prices.length);

		for (uint i = 0; i < prices.length; ++i)
			mm.push(Order(Kind.Buy, prices[i], amt, address(this)));

		for (uint i = 0; i < prices.length; ++i) {
			(Kind kind, uint price, uint qtt, address who) = mm.oBuy(i);
			emit O(Order(kind, price, qtt, who));
		}
	}

	function test_cancel() public {
		uint[] memory prices = new uint[](4);
		prices[0] = 10;
		prices[1] = 100_000;
		prices[2] = 1;
		prices[3] = 100;

		uint amt = 10**9;

		uint bal = token1.balanceOf(address(this));

		token1.approve(address(mm), amt * prices.length);

		for (uint i = 0; i < prices.length; ++i)
			mm.push(Order(Kind.Sell, prices[i], amt, address(this)));

		assertEq(token1.balanceOf(address(this)), bal - amt * prices.length);

		for (uint i = 0; i < prices.length; ++i)
			mm.cancelOneSellOrder();

		assertEq(token1.balanceOf(address(this)), bal);
	}

	function test_hack() public {
		User user = new User(token1, token2, mm);
		User hacker = new User(token1, token2, mm);

		token1.transfer(address(user), 1_000_000);
		token1.transfer(address(hacker), 1_000);

		token2.transfer(address(user), 1_000_000);

		// user is selling at 1:1
		// sends 1000 token1 tokens to MM
		user.push(Order(Kind.Sell, 10**9, 1_000, address(user)));

		assertEq(token1.balanceOf(address(hacker)), 1_000);
		// hacker overwrites user's order
		hacker.push(Order(Kind.Sell, 10**10, 1_000, address(hacker)));
		// hacker cancels the orders and collects their own
		// plus user's token1 tokens
		hacker.cancelOneSellOrder();
		hacker.cancelOneSellOrder();
		// RUGPULL
		assertEq(token1.balanceOf(address(hacker)), 2_000);
	}
}

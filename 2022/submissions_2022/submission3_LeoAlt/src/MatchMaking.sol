// SPDX-License-Identifier: GPL-3
pragma solidity >=0.8.6;

import "solmate/tokens/ERC20.sol";

uint constant TH = 10**9;

enum Kind {
	Buy,
	Sell
}

struct Order {
	Kind kind;
	// Price is defined as number of token2 per 10^9 token1
	// to allow some granularity in the swaps without using
	// complicated fixed point stuff.
	// price = 10^9 means the ratio is 1:1
	// price = 1 means 1 token2 = 10^9 token1
	// price = 10^10 means 10 token2 = 1 token1
	uint price;
	uint qtt;
	address who;
}

function lt(Order storage a, Order storage b) view returns (bool) {
	return a.price < b.price;
}

function gt(Order storage a, Order storage b) view returns (bool) {
	return a.price > b.price;
}

function min(uint a, uint b) pure returns (uint) {
	return a < b ? a : b;
}

contract MatchMaking {
	// Sell token1, buy token2
	ERC20 immutable token1;
	ERC20 immutable token2;

	// Keep two lists:
	// Sell list, sorted dec, smaller price matches first.
	// Buy list, sorted inc, bigger price matches first.

	Order[] public oSell;
	Order[] public oBuy;

	constructor(ERC20 t1, ERC20 t2) {
		token1 = t1;
		token2 = t2;
	}

	bool lock;
	modifier noReentrancy {
		require(!lock);
		lock = true;
		_;
		lock = false;
	}

	/** PUBLIC FUNCTIONS */

	function matchAll() public noReentrancy {
		while (matchOne()) {}
	}

	function push(Order memory o) public noReentrancy {
		require(isValid(o.kind, o.price, o.qtt));

		if (o.kind == Kind.Sell) {
			// User gives token1 to receive token2.
			require(token1.transferFrom(msg.sender, address(this), o.qtt));
			insertSell(o);
		} else {
			// User gives token2 to receive token1.
			require(token2.transferFrom(msg.sender, address(this), o.qtt));
			insertBuy(o);
		}
	}

	// Allow the user to cancel one sell or one buy order at a time
	// so their tokens aren't stuck forever.

	function cancelOneSellOrder() public noReentrancy {
		// Adjust data structures before returning funds.
		uint q = cancelOneOrder(oSell);
		returnFunds(token1, msg.sender, q);
	}

	function cancelOneBuyOrder() public noReentrancy {
		// Adjust data structures before returning funds.
		uint q = cancelOneOrder(oBuy);
		returnFunds(token2, msg.sender, q);
	}

	/************************************************/

	/* MUTATING STATE INTERNAL FUNCTIONS */

	function matchOne() internal returns (bool) {
		if (oSell.length == 0 || oBuy.length == 0)
			return false;

		Order storage s = oSell[oSell.length - 1];
		Order storage b = oBuy[oBuy.length - 1];

		// Only match if price is the same.
		if (s.price != b.price)
			return false;

		// Even if one order would receive more than its counterpart offers,
		// we limit the amount of this order to the quantity that the other provides.
		uint sGets = min(receives(s.kind, s.price, s.qtt), b.qtt);
		uint bGets = min(receives(b.kind, b.price, b.qtt), s.qtt);

		// Used up tokens.
		s.qtt -= bGets;
		b.qtt -= sGets;

		require(token2.transfer(s.who, sGets));
		require(token1.transfer(b.who, bGets));

		// The orders may have become invalid now if they don't
		// have enough tokens to swap into at least 1 of the other.
		// In that case they get cancelled and the remaining funds
		// are returned.

		if (!isValid(s.kind, s.price, s.qtt)) {
			oSell.pop();
			returnFunds(token1, s.who, s.qtt);
		}

		if (!isValid(b.kind, b.price, b.qtt)) {
			oBuy.pop();
			returnFunds(token2, b.who, b.qtt);
		}

		return true;
	}

	function insertSell(Order memory coke) internal {
		// oSell is sorted dec, so our compare function is gt
		// for the backwards search.
		update(oSell, coke, gt);
	}

	function insertBuy(Order memory coke) internal {
		// oSell is sorted inc, so our compare function is lt
		// for the backwards search.
		update(oBuy, coke, lt);
	}
	
	function update(
		Order[] storage can,
		Order memory coke,
		function (Order storage, Order storage) internal view returns (bool) compare
	) internal {
		// Create new element.
		can.push(coke);
		// Swap backwards until correct place is reached.
		for (uint i = can.length - 1; i > 0 && compare(can[i], can[i - 1]); --i) {
			Order storage temp = can[i - 1];
			can[i - 1] = can[i];
			can[i] = temp;
		}
	}
	
	function cancelOneOrder(Order[] storage can) internal returns (uint) {
		uint qtt = 0;
		uint from = 0;
		bool found = false;
		for (uint i = 0; i < can.length; ++i)
			if (can[i].who == msg.sender) {
				from = i;
				found = true;
				break;
			}
		require(found);
		qtt = can[from].qtt;
		// Shift left all the orders that are staying.
		for (uint i = from; i < can.length - 1; ++i)
			can[i] = can[i + 1];
		can.pop();
		return qtt;
	}

	function returnFunds(ERC20 t, address who, uint q) internal {
		if (q > 0)
			require(t.transfer(who, q));
	}

	/**************************/

	/* PURE INTERNAL FUNCTIONS */

	function receives(Kind kind, uint price, uint qtt) internal pure returns (uint) {
		if (kind == Kind.Sell)
			return (qtt * price) / TH;
		return (qtt * TH) / price;
	}

	// Ideally we'd pass an `Order` arg, but we need it for both
	// memory and storage so to avoid duplication just pass the members.
	function isValid(Kind kind, uint price, uint qtt) internal pure returns (bool) {
		return receives(kind, price, qtt) > 0;
	}

	/**************************/
}

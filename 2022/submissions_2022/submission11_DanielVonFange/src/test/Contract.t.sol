// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "ds-test/test.sol";
import "../MockToken.sol";
import "../LipPool.sol";

contract ContractTest is DSTest {
  MockToken a; 
  MockToken b;
  LipPool pool;
  PoolUser firstHolder;
  PoolUser aviatrix;
  PoolUser socialite;
  PoolUser attacker;


  function setUp() public {
    a = new MockToken("LIP","LIP");
    b = new MockToken("DAI","DAI");
    pool = new LipPool(address(a), address(b));

    firstHolder = new PoolUser(address(a), address(b));
    firstHolder.initializePool(pool);

    aviatrix = new PoolUser(address(a), address(b));
    socialite = new PoolUser(address(a), address(b));

    attacker = new PoolUser(address(a), address(b));

  }

  function testPOC() public{
    uint256 amount = 1e24;
    uint256 startingCash = 1e23;
    a.mintTo(address(attacker), startingCash);
    b.mintTo(address(attacker), startingCash);

    // -----
    // ** Insert hack transactions by attacker below: **
    // -----
    attacker.addLiquidity(pool, amount);
    // ..?

    // And afterwords:
    // Pool should be be drained
    // assertLt(a.balanceOf(address(pool)), 100 * 1e18, "Pool not drained");
    // assertLt(b.balanceOf(address(pool)), 100 * 1e18, "Pool not drained");
    // Attacker should have more than they started with
    // assertGt(a.balanceOf(address(attacker)), startingCash, "Attacker should be richer");
    // assertGt(b.balanceOf(address(attacker)), startingCash, "Attacker should be richer");
  }

  function testTestSetup() public {
    assertEq(pool.totalSupply(), 1e24);
    assertEq(pool.balanceOf(address(firstHolder)), 1e24);
    assertEq(a.balanceOf(address(firstHolder)), 0);
    assertEq(b.balanceOf(address(firstHolder)), 0);
  }

  function testFuzzAddingAndRemovingLiquidity(uint256 amount) public {
    if(amount > 1e36){
      return;
    }
    a.mintTo(address(aviatrix), 1e70);
    b.mintTo(address(aviatrix), 1e70);
    
    aviatrix.addLiquidity(pool, amount);
    aviatrix.removeLiquidity(pool, amount);

    // Adding then removing should aways lose money!
    assertLt(a.balanceOf(address(aviatrix)), 1e70);
    assertLt(b.balanceOf(address(aviatrix)), 1e70);
  }

  function testFuzzAddingAndRemovingLiquidityAtDifferentRatios(uint256 amount, uint256 extraA, uint256 extraB) public {
    if(amount > 1e36){
      return;
    }
    if(extraA > 1e36){
      return;
    }
    if(extraB > 1e36){
      return;
    }

    // First give the pool some amount of each token, to represent both profit and changing prices
    a.mintTo(address(pool), extraA);
    b.mintTo(address(pool), extraB);

    // Give test user funds
    a.mintTo(address(aviatrix), 1e70);
    b.mintTo(address(aviatrix), 1e70);
    
    // Add and remove
    aviatrix.addLiquidity(pool, amount);
    aviatrix.removeLiquidity(pool, amount);

    // Adding then removing should aways lose money!
    assertLt(a.balanceOf(address(aviatrix)), 1e70);
    assertLt(b.balanceOf(address(aviatrix)), 1e70);
  }

  

  function testAddLiquidity() public {
    a.mintTo(address(aviatrix), 2000 * 1e18);
    b.mintTo(address(aviatrix), 20000 * 1e18);
    aviatrix.addLiquidity(pool, 1e24);

    assertEq(pool.balanceOf(address(aviatrix)), 1e24);
  }

  function testRemoveLiquidity() public {
    a.mintTo(address(aviatrix), 2000 * 1e18);
    b.mintTo(address(aviatrix), 20000 * 1e18);
    aviatrix.addLiquidity(pool, 1e24);
    assertEq(pool.balanceOf(address(aviatrix)), 1e24);

    aviatrix.removeLiquidity(pool, 1e24);
    assertEq(pool.balanceOf(address(aviatrix)), 0);
  }

  function testEarlyProfit() public {
    a.mintTo(address(aviatrix), 2000 * 1e18);
    b.mintTo(address(aviatrix), 20000 * 1e18);
    a.mintTo(address(socialite), 4000 * 1e18);
    b.mintTo(address(socialite), 40000 * 1e18);
    

    aviatrix.addLiquidity(pool, 1e24);
    socialite.addLiquidity(pool, 2e24);
    aviatrix.removeLiquidity(pool, 1e24);

    // Profit from being early
    assertGt(a.balanceOf(address(aviatrix)), 2000 * 1e18);
    assertGt(b.balanceOf(address(aviatrix)), 20000 * 1e18);
  }

}


// Helper contract for tests
contract PoolUser{
    MockToken a; 
    MockToken b;

    constructor(address a_, address b_){
        a = MockToken(a_);
        b = MockToken(b_);
    }

    function approve(LipPool pool) public {
       a.approve(address(pool), type(uint256).max);
       b.approve(address(pool), type(uint256).max); 
    }

    function addLiquidity(LipPool pool, uint256 amount) public {
       approve(pool);
      pool.addLiquidity(amount);
    }

    function removeLiquidity(LipPool pool, uint256 amount) public {
      pool.approve(address(pool), type(uint256).max); 
      pool.removeLiquidity(amount);
    }

    function initializePool(LipPool pool) public {
        approve(pool);
        a.mintTo(address(this), 1000 * 1e18);
        b.mintTo(address(this), 10000 * 1e18);
        pool.initialize();
    }
}

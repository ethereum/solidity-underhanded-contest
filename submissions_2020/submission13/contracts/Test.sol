// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Proxy.sol";

contract FriendlyApp {
    function hello() external pure returns (string memory) {
       return "World!"; 
    }
}

contract FriendlyApp2 {
    function lorem() external pure returns (string memory) {
       return "Ipsum!"; 
    }
}

contract Test {
    
    // Test that deployments set a timelock on the selector
    function testTimelock() public returns (uint256 expectedTimelock, uint256 actualTimelock) {
        // Create a proxt with a 5 day timelock
        uint256 timelockDuration = 5*24*60*60;
        Proxy proxy = new Proxy(timelockDuration);
        
        // Register friendly app
        proxy.register(FriendlyApp(0).hello.selector, type(FriendlyApp).creationCode);
        
        // Ensure timelock was set
        expectedTimelock = block.timestamp + timelockDuration;
        actualTimelock = proxy.timelockBySelector(FriendlyApp(0).hello.selector);
        require(expectedTimelock == actualTimelock, "testTimelock() failed");
    }

    // Test calling a deployed app.
    function testCall() public returns (string memory actualOutput) {
        // Create a proxy with no timelock so we can test call atomically.
        Proxy proxy = new Proxy(0);
        
        // Register friendly app
        proxy.register(FriendlyApp(0).hello.selector, type(FriendlyApp).creationCode);

        // Ensure can call registered app
        string memory expectedOutput = (new FriendlyApp()).hello();
        actualOutput = FriendlyApp(address(proxy)).hello();
        _assertEqual(expectedOutput, actualOutput, "testCall() failed");
    }
    
    // Test calling multiple apps. This ensures routing is unique.
    function testMultipleCalls() public returns (string memory actualOutput1, string memory actualOutput2) {
        // Create a proxy with no timelock so we can test call atomically.
        Proxy proxy = new Proxy(0);
        
        // Register friendly app
        proxy.register(FriendlyApp(0).hello.selector, type(FriendlyApp).creationCode);
        proxy.register(FriendlyApp2(0).lorem.selector, type(FriendlyApp2).creationCode);

        // Ensure can call 1st registered app
        string memory expectedOutput1 = (new FriendlyApp()).hello();
        actualOutput1 = FriendlyApp(address(proxy)).hello();
        _assertEqual(expectedOutput1, actualOutput1, "testCall() failed");

        // Ensure can call 2nd registered app
        string memory expectedOutput2 = (new FriendlyApp2()).lorem();
        actualOutput2 = FriendlyApp2(address(proxy)).lorem();
        _assertEqual(expectedOutput2, actualOutput2, "testCall() failed");
    }
    
    function _assertEqual(string memory a, string memory b, string memory message) internal pure {
        require(keccak256(bytes(a)) == keccak256(bytes(b)), message);
    }
}
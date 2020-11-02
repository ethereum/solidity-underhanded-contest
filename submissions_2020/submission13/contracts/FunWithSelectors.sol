// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

contract FunWithSelectors {
    
    // When written in solidity, this will have the desired effect.
    function test() public pure returns (bytes4 selector, bytes32 selectorWord) {
        selector = 0x12345678;
        selectorWord = selector;
    }
    
    // When written in assembly, the `selector` will actually be zero.
    function test2() public pure returns (bytes4 selector, bytes32 selectorWord) {
        assembly {
            selector := 0x12345678
            selectorWord := selector
        }
    }
}
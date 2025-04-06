// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Secp256k1} from "../src/Secp256k1Lib.sol";

contract Secp256k1Test is Test {
    using Secp256k1 for *;

    function setUp() public {}

    function test_isInfinity() public pure {
        uint256 x = 0;
        uint256 y = 0;
        assertEq(Secp256k1.isInfinity(x, y), true);
    }

    function testFuzz_isInfinity(uint256 x, uint256 y) public pure {
        vm.assume(x != 0 || y != 0);
        assertEq(Secp256k1.isInfinity(x, y), false);
    }
}

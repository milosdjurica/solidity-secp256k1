// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Secp256k1} from "../src/Secp256k1Lib.sol";

contract Secp256k1Test is Test {
    using Secp256k1 for *;

    // secp256k1 Generator Point (G)
    uint256 constant Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 constant Gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

    // 2G (Result of G + G)
    uint256 constant G2x = 0xC6047F9441ED7D6D3045406E95C07CD85C778E4B8CEF3CA7ABAC09B95C709EE5;
    uint256 constant G2y = 0x1AE168FEA63DC339A3C58419466CEAEEF7F632653266D0E1236431A950CFE52A;

    function setUp() public pure {
        // Verify test points are valid before testing
        require(Secp256k1.isOnCurve(Gx, Gy), "G not on curve");
        require(Secp256k1.isOnCurve(G2x, G2y), "2G not on curve");
    }

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! isInfinity() TESTS
    // ! -----------------------------------------------------------------------------------------------------------------------
    function test_isInfinity_True() public pure {
        uint256 x = 0;
        uint256 y = 0;
        assertEq(Secp256k1.isInfinity(x, y), true);
    }

    function testFuzz_isInfinity_False(uint256 x, uint256 y) public pure {
        vm.assume(x != 0 || y != 0);
        assertEq(Secp256k1.isInfinity(x, y), false);
    }

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! isOnCurve() TESTS
    // ! -----------------------------------------------------------------------------------------------------------------------
    function test_isOnCurve_InfinityPoint_False() public pure {
        uint256 x = 0;
        uint256 y = 0;
        assertFalse(Secp256k1.isOnCurve(x, y));
    }

    function test_isOnCurve_True() public pure {
        assertTrue(Secp256k1.isOnCurve(Gx, Gy));
        assertTrue(Secp256k1.isOnCurve(G2x, G2y));
    }

    // ! Line below is for reverting with internal function calls -> https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert#error
    /// forge-config: default.allow_internal_expect_revert = true
    function testFuzz_isOnCurve_RevertIf_InvalidCoordinate_X(uint256 x) public {
        x = bound(x, Secp256k1.p, UINT256_MAX);
        vm.expectRevert(abi.encodeWithSelector(Secp256k1.Secp256k1__InvalidCoordinate.selector, x));
        Secp256k1.isOnCurve(x, Gy);
    }

    // ! Line below is for reverting with internal function calls -> https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert#error
    /// forge-config: default.allow_internal_expect_revert = true
    function testFuzz_isOnCurve_RevertIf_InvalidCoordinate_Y(uint256 y) public {
        y = bound(y, Secp256k1.p, UINT256_MAX);
        vm.expectRevert(abi.encodeWithSelector(Secp256k1.Secp256k1__InvalidCoordinate.selector, y));
        Secp256k1.isOnCurve(Gx, y);
    }

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! addPoints() TESTS FOR GAS
    // ! -----------------------------------------------------------------------------------------------------------------------
    function test_addPointsGasCosts() public view {
        // Test 1: Point doubling (G + G)
        uint256 gasBefore = gasleft();
        (uint256 x1, uint256 y1) = Secp256k1.addPoints(Gx, Gy, Gx, Gy);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for point doubling (G + G):", gasUsed);
        require(x1 == G2x && y1 == G2y, "Invalid doubling result");

        // Test 2: Point addition (G + 2G)
        gasBefore = gasleft();
        (uint256 x2, uint256 y2) = Secp256k1.addPoints(Gx, Gy, G2x, G2y);
        gasUsed = gasBefore - gasleft();

        console.log("Gas used for point addition (G + 2G):", gasUsed);
        require(Secp256k1.isOnCurve(x2, y2), "Invalid addition result");
        // TODO -> add test for -> (0,0) + G
        // TODO -> add test for -> G + (0,0)
        // TODO -> add test for -> (0,0) + (0,0)
        // TODO -> add test for -> 2G + G
        // TODO -> add gas tests for unchecked
    }
}

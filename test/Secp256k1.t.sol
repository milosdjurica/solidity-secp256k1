// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Secp256k1} from "../src/Secp256k1Lib.sol";

contract Secp256k1Test is Test {
    using Secp256k1 for *;

    // secp256k1 Generator Point (G)
    uint256 constant Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 constant Gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

    uint256 constant GyNeg = 0xb7c52588d95c3b9aa25b0403f1eef75702e84bb7597aabe663b82f6f04ef2777;

    // 2G (Result of G + G)
    uint256 constant G2x = 0xC6047F9441ED7D6D3045406E95C07CD85C778E4B8CEF3CA7ABAC09B95C709EE5;
    uint256 constant G2y = 0x1AE168FEA63DC339A3C58419466CEAEEF7F632653266D0E1236431A950CFE52A;

    function setUp() public pure {
        // Verify test points are valid before testing
        require(Secp256k1.isOnCurve(Gx, Gy), "G not on curve");
        require(Secp256k1.isOnCurve(G2x, G2y), "2G not on curve");
        require(Secp256k1.isOnCurve(Gx, GyNeg), "G negated not on curve");
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
        assertTrue(Secp256k1.isOnCurve(Gx, GyNeg));
    }

    // ! Expecting revert with internal function calls -> https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert#error
    /// forge-config: default.allow_internal_expect_revert = true
    function testFuzz_isOnCurve_RevertIf_InvalidCoordinate_X(uint256 x) public {
        x = bound(x, Secp256k1.p, UINT256_MAX);
        vm.expectRevert(abi.encodeWithSelector(Secp256k1.Secp256k1__InvalidCoordinate.selector, x));
        Secp256k1.isOnCurve(x, Gy);
    }

    // ! Expecting revert with internal function calls -> https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert#error
    /// forge-config: default.allow_internal_expect_revert = true
    function testFuzz_isOnCurve_RevertIf_InvalidCoordinate_Y(uint256 y) public {
        y = bound(y, Secp256k1.p, UINT256_MAX);
        vm.expectRevert(abi.encodeWithSelector(Secp256k1.Secp256k1__InvalidCoordinate.selector, y));
        Secp256k1.isOnCurve(Gx, y);
    }

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! negatePoint() TESTS
    // ! -----------------------------------------------------------------------------------------------------------------------
    function test_negatePoint_Infinity() public pure {
        (uint256 x, uint256 y) = Secp256k1.negatePoint(0, 0);
        assertEq(x, 0);
        assertEq(y, 0);
    }

    function test_negatePoint_G() public pure {
        (uint256 x, uint256 yNeg) = Secp256k1.negatePoint(Gx, Gy);
        assertEq(x, Gx);
        assertEq(yNeg, GyNeg);
        (uint256 x_unchanged, uint256 y) = Secp256k1.negatePoint(Gx, GyNeg);
        assertEq(x_unchanged, Gx);
        assertEq(y, Gy);
    }

    // ! Expecting revert with internal function calls -> https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert#error
    /// forge-config: default.allow_internal_expect_revert = true
    function testFuzz_negatePoint_RevertIf_InvalidCoordinate_X(uint256 x) public {
        x = bound(x, Secp256k1.p, UINT256_MAX);
        uint256 y = 1;
        vm.expectRevert(abi.encodeWithSelector(Secp256k1.Secp256k1__InvalidCoordinate.selector, x));
        Secp256k1.negatePoint(x, y);
    }

    // ! Expecting revert with internal function calls -> https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert#error
    /// forge-config: default.allow_internal_expect_revert = true
    function testFuzz_negatePoint_RevertIf_InvalidCoordinate_Y(uint256 y) public {
        uint256 x = 1;
        y = bound(y, Secp256k1.p, UINT256_MAX);
        vm.expectRevert(abi.encodeWithSelector(Secp256k1.Secp256k1__InvalidCoordinate.selector, y));
        Secp256k1.negatePoint(x, y);
    }

    // ! Expecting revert with internal function calls -> https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert#error
    /// forge-config: default.allow_internal_expect_revert = true
    function testFuzz_negatePoint_RevertIf_InvalidPoint(uint256 x, uint256 y) public {
        x = bound(x, 0, Secp256k1.p - 1);
        y = bound(y, 0, Secp256k1.p - 1);
        vm.assume(!Secp256k1.isOnCurve(x, y));
        vm.assume(x != 0 || y != 0);
        vm.expectRevert(abi.encodeWithSelector(Secp256k1.Secp256k1__InvalidPoint.selector, x, y));
        Secp256k1.negatePoint(x, y);
    }

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! negatePointUnchecked() TESTS
    // ! -----------------------------------------------------------------------------------------------------------------------
    function test_negatePointUnchecked_Infinity() public pure {
        (uint256 x, uint256 yNeg) = Secp256k1.negatePointUnchecked(0, 0);
        assertEq(x, 0);
        assertEq(yNeg, 0);
    }

    function testFuzz_negatePointUnchecked_Passes(uint256 x, uint256 y) public pure {
        x = bound(x, 1, Secp256k1.p - 1);
        y = bound(y, 1, Secp256k1.p - 1);
        (uint256 xNeg, uint256 yNeg) = Secp256k1.negatePointUnchecked(x, y);
        assertEq(x, xNeg);
        assertEq(yNeg, Secp256k1.p - y);
    }

    // ! Expecting revert with internal function calls -> https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert#error
    /// forge-config: default.allow_internal_expect_revert = true
    function testFuzz_negatePointUnchecked_RevertIf_OutOfBounds(uint256 x, uint256 y) public {
        x = bound(x, Secp256k1.p + 1, UINT256_MAX);
        y = bound(y, Secp256k1.p + 1, UINT256_MAX);
        console.log(x, y);
        // underflow or overflow
        vm.expectRevert(0x11);
        Secp256k1.negatePointUnchecked(x, y);
    }

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! addPoints() TESTS
    // ! -----------------------------------------------------------------------------------------------------------------------
    function test_addPoints_WithInfinity() public view {
        uint256 gasBefore;
        uint256 gasUsed;

        gasBefore = gasleft();
        (uint256 x, uint256 y) = Secp256k1.addPoints(0, 0, Gx, Gy);
        gasUsed = gasBefore - gasleft();
        console.log("Gas used for Infinity + G:", gasUsed);
        assertEq(x, Gx);
        assertEq(y, Gy);

        gasBefore = gasleft();
        (uint256 x1, uint256 y1) = Secp256k1.addPoints(Gx, Gy, 0, 0);
        gasUsed = gasBefore - gasleft();
        console.log("Gas used for point G + Infinity:", gasUsed);
        assertEq(x1, Gx);
        assertEq(y1, Gy);
    }

    function test_addPoints_Double() public view {
        uint256 gasBefore;
        uint256 gasUsed;
        gasBefore = gasleft();
        (uint256 x, uint256 y) = Secp256k1.addPoints(Gx, Gy, Gx, Gy);
        gasUsed = gasBefore - gasleft();
        console.log("Gas used for G + G:", gasUsed);
        assertEq(x, G2x);
        assertEq(y, G2y);
    }

    function test_addPoints_AddNegated() public view {
        uint256 gasBefore;
        uint256 gasUsed;
        gasBefore = gasleft();
        (uint256 x, uint256 y) = Secp256k1.addPoints(Gx, Gy, Gx, GyNeg);
        gasUsed = gasBefore - gasleft();
        console.log("Gas used for G + GNeg:", gasUsed);
        assertEq(x, 0);
        assertEq(y, 0);
    }

    function test_addPoints_WorkingExamples() public view {
        uint256 gasBefore;
        uint256 gasUsed;

        gasBefore = gasleft();
        (uint256 x, uint256 y) = Secp256k1.addPoints(0, 0, G2x, G2y);
        gasUsed = gasBefore - gasleft();
        console.log("Gas used for Infinity + G2:", gasUsed);
        assertEq(x, G2x);
        assertEq(y, G2y);

        gasBefore = gasleft();
        (uint256 x1, uint256 y1) = Secp256k1.addPoints(G2x, G2y, 0, 0);
        gasUsed = gasBefore - gasleft();
        console.log("Gas used for G2 + Infinity:", gasUsed);
        assertEq(x1, G2x);
        assertEq(y1, G2y);

        gasBefore = gasleft();
        (uint256 x2, uint256 y2) = Secp256k1.addPoints(Gx, GyNeg, 0, 0);
        gasUsed = gasBefore - gasleft();
        console.log("Gas used for GNeg + Infinity:", gasUsed);
        assertEq(x2, Gx);
        assertEq(y2, GyNeg);

        gasBefore = gasleft();
        (uint256 x3, uint256 y3) = Secp256k1.addPoints(0, 0, Gx, GyNeg);
        gasUsed = gasBefore - gasleft();
        console.log("Gas used for Infinity + GNeg:", gasUsed);
        assertEq(x3, Gx);
        assertEq(y3, GyNeg);

        gasBefore = gasleft();
        Secp256k1.addPoints(Gx, Gy, G2x, G2y);
        gasUsed = gasBefore - gasleft();
        console.log("Gas used for G + G2:", gasUsed);

        gasBefore = gasleft();
        Secp256k1.addPoints(G2x, G2y, Gx, GyNeg);
        gasUsed = gasBefore - gasleft();
        console.log("Gas used for G2 + GNeg:", gasUsed);
    }

    // ! Expecting revert with internal function calls -> https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert#error
    /// forge-config: default.allow_internal_expect_revert = true
    function testFuzz_addPoints_RevertIf_InvalidCoordinate_X(uint256 x) public {
        x = bound(x, Secp256k1.p, UINT256_MAX);
        uint256 y = 1;
        vm.expectRevert(abi.encodeWithSelector(Secp256k1.Secp256k1__InvalidCoordinate.selector, x));
        Secp256k1.addPoints(x, y, Gx, Gy);
    }

    // ! Expecting revert with internal function calls -> https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert#error
    /// forge-config: default.allow_internal_expect_revert = true
    function testFuzz_addPoints_RevertIf_InvalidCoordinate_Y(uint256 y) public {
        uint256 x = 1;
        y = bound(y, Secp256k1.p, UINT256_MAX);
        vm.expectRevert(abi.encodeWithSelector(Secp256k1.Secp256k1__InvalidCoordinate.selector, y));
        Secp256k1.addPoints(x, y, Gx, Gy);
    }

    // ! Expecting revert with internal function calls -> https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert#error
    /// forge-config: default.allow_internal_expect_revert = true
    function testFuzz_addPoints_RevertIf_InvalidPoint(uint256 x, uint256 y) public {
        x = bound(x, 0, Secp256k1.p - 1);
        y = bound(y, 0, Secp256k1.p - 1);
        vm.assume(!Secp256k1.isOnCurve(x, y));
        vm.assume(x != 0 || y != 0);
        vm.expectRevert(abi.encodeWithSelector(Secp256k1.Secp256k1__InvalidPoint.selector, x, y));
        Secp256k1.addPoints(x, y, Gx, Gy);
    }
    // TODO -> add gas tests for unchecked
    // TODO -> add tests for doubling point

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! modInverse() TESTS
    // ! -----------------------------------------------------------------------------------------------------------------------
    function testFuzz_modInverse(uint256 number) public pure {
        number = bound(number, 1, Secp256k1.p - 1);
        uint256 inverse = Secp256k1.modInverse(number);
        assertEq(mulmod(number, inverse, Secp256k1.p), 1);
    }

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! modPow() TESTS
    // ! -----------------------------------------------------------------------------------------------------------------------
    function testFuzz_ModPow(uint256 base, uint256 exponent) public pure {
        // To avoid high gas cost in the fuzz test, restricted the exponent to a reasonable range.
        vm.assume(exponent < 1_000_000);

        uint256 result = Secp256k1.modPow(base, exponent);
        uint256 expected = 1;
        for (uint256 i = 0; i < exponent; i++) {
            expected = mulmod(expected, base, Secp256k1.p);
        }
        assertEq(result, expected);
    }
}

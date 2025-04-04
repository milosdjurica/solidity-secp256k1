// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Secp256k1 {
    // Curve parameters for secp256k1
    uint256 constant a = 0;
    uint256 constant b = 7;
    // p = 2^256 - 2^32 - 977
    uint256 constant p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    // Check if the point is infinity
    function isInfinity(uint256 x, uint256 y) internal pure returns (bool) {
        return x == 0 && y == 0;
    }

    // y^2 ≡ x^3 + 7 (mod p)
    // Check if the point is on curve
    function isOnCurve(uint256 x, uint256 y) internal pure returns (bool) {
        uint256 leftHandSide = mulmod(y, y, p); // y^2 mod p
        uint256 xCubed = mulmod(x, mulmod(x, x, p), p); // x^3 mod p
        uint256 rightHandSide = addmod(xCubed, 7, p); // (x*3 + 8) mod p
        return leftHandSide == rightHandSide;
    }

    function addPoint() internal {}
    function negatePoint() internal {}
    function orderOfPoint() internal {}
    function scalarMultiply() internal {}
}

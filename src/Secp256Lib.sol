// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// ! y^2 = x^3 + ax + b = x^3 + 7
library Secp256k1 {
    error Secp256k1__InvalidPoint(uint256 x, uint256 y);

    // Curve parameters for secp256k1
    uint256 constant a = 0;
    uint256 constant b = 7;
    // p = 2^256 - 2^32 - 977
    uint256 constant p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    modifier onlyValidPoint(uint256 x, uint256 y) {
        if (!isOnCurve(x, y)) revert Secp256k1__InvalidPoint(x, y);
        _;
    }

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

    function negatePoint(uint256 x, uint256 y) internal pure onlyValidPoint(x, y) returns (uint256, uint256) {
        return negatePointUnchecked(x, y);
    }

    function negatePointUnchecked(uint256 x, uint256 y) internal pure returns (uint256, uint256) {
        if (isInfinity(x, y)) return (x, y);
        return (x, p - y);
    }

    function addPoint(uint256 x1, uint256 y1, uint256 x2, uint256 y2)
        internal
        pure
        onlyValidPoint(x1, y1)
        onlyValidPoint(x2, y2)
        returns (uint256, uint256)
    {
        return addPointUnchecked(x1, y1, x2, y2);
    }

    function addPointUnchecked(uint256 x1, uint256 y1, uint256 x2, uint256 y2)
        internal
        pure
        returns (uint256, uint256)
    {
        if (isInfinity(x1, y1)) return (x2, y2);
        if (isInfinity(x2, y2)) return (x1, y1);

        if (x1 == x2 && (y1 + y2) % p == 0) return (0, 0); // point at infinity

        uint256 m = calculateSlope(x1, y1, x2, y2);
    }

    function calculateSlope(uint256 x1, uint256 y1, uint256 x2, uint256 y2) internal pure returns (uint256) {
        uint256 numerator;
        uint256 denominator;

        // Point Doubling
        if (x1 == x2 && y1 == y2) {
            // (3 * x1^2 + a) mod p, but since `a` is 0 , we can ignore it
            numerator = mulmod(3, mulmod(x1, x1, p), p);

            // (2 * y1) mod p
            denominator = mulmod(2, y1, p);
        } else {
            // Point addition
            numerator = addmod(y2, p - y1, p);
            denominator = addmod(x2, p - x1, p);
        }

        return mulmod(numerator, modInverse(denominator), p);
    }

    function modInverse(uint256 toInvert) internal pure returns (uint256) {
        return modPow(toInvert, p - 2);
    }

    function modPow(uint256 base, uint256 exp) internal pure returns (uint256) {
        // TODO
    }

    function orderOfPoint() internal {}
    function scalarMultiply() internal {}
}

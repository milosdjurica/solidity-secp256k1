// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// ! y^2 = x^3 + ax + b = x^3 + 7
library Secp256k1 {
    error Secp256k1__InvalidPoint(uint256 x, uint256 y);
    error Secp256k1__InvalidCoordinate(uint256 coordinate);

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
        if (x >= p) revert Secp256k1__InvalidCoordinate(x);
        if (y >= p) revert Secp256k1__InvalidCoordinate(y);

        uint256 leftHandSide = mulmod(y, y, p); // y^2 mod p
        uint256 xCubed = mulmod(x, mulmod(x, x, p), p); // x^3 mod p
        uint256 rightHandSide = addmod(xCubed, 7, p); // (x*3 + 8) mod p
        return leftHandSide == rightHandSide;
    }

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! NEGATE POINT
    // ! -----------------------------------------------------------------------------------------------------------------------
    function negatePoint(uint256 x, uint256 y) internal pure onlyValidPoint(x, y) returns (uint256, uint256) {
        return negatePointUnchecked(x, y);
    }

    function negatePointUnchecked(uint256 x, uint256 y) internal pure returns (uint256, uint256) {
        if (isInfinity(x, y)) return (x, y);
        return (x, p - y);
    }

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! ADD POINTS
    // ! -----------------------------------------------------------------------------------------------------------------------
    function addPoints(uint256 x1, uint256 y1, uint256 x2, uint256 y2)
        internal
        pure
        onlyValidPoint(x1, y1)
        onlyValidPoint(x2, y2)
        returns (uint256, uint256)
    {
        return addPointsUnchecked(x1, y1, x2, y2);
    }

    function addPointsUnchecked(uint256 x1, uint256 y1, uint256 x2, uint256 y2)
        internal
        pure
        returns (uint256, uint256)
    {
        if (isInfinity(x1, y1)) return (x2, y2);
        if (isInfinity(x2, y2)) return (x1, y1);

        if (x1 == x2) {
            if (y1 == y2) return doublePointUnchecked(x1, y1); // Doubling a point
            if ((y1 + y2) % p == 0) return (0, 0); // Point at infinity
        }

        // ! Calculate slope
        uint256 numerator = addmod(y2, p - y1, p);
        uint256 denominator = addmod(x2, p - x1, p);
        uint256 m = mulmod(numerator, modInverse(denominator), p);

        // ! x3 = m^2 - x1 - x2 mod p = m^2 - (x1 + x2) mod p
        uint256 x3 = addmod(mulmod(m, m, p), p - addmod(x1, x2, p), p);
        // ! y3 = m * (x1 - x3) - y1 mod p
        uint256 y3 = addmod(mulmod(m, addmod(x1, p - x3, p), p), p - y1, p);

        return (x3, y3);
    }

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! POINT DOUBLING
    // ! -----------------------------------------------------------------------------------------------------------------------
    function doublePoint(uint256 x, uint256 y) internal pure onlyValidPoint(x, y) returns (uint256, uint256) {
        if (isInfinity(x, y)) return (0, 0);
        return doublePointUnchecked(x, y);
    }

    function doublePointUnchecked(uint256 x1, uint256 y1) internal pure returns (uint256, uint256) {
        // (3 * x1^2 + a) mod p, but since `a` is 0 , we can ignore it
        uint256 numerator = mulmod(3, mulmod(x1, x1, p), p);
        // (2 * y1) mod p
        uint256 denominator = mulmod(2, y1, p);
        uint256 m = mulmod(numerator, modInverse(denominator), p);

        // ! x3 = m^2 - x1 - x2 mod p = m^2 - 2x1 mod p
        uint256 x3 = addmod(mulmod(m, m, p), p - addmod(x1, x1, p), p);
        // ! y3 = m * (x1 - x3) - y1 mod p
        uint256 y3 = addmod(mulmod(m, addmod(x1, p - x3, p), p), p - y1, p);

        return (x3, y3);
    }

    function modInverse(uint256 toInvert) internal pure returns (uint256) {
        return modPow(toInvert, p - 2);
    }

    function modPow(uint256 base, uint256 exp) internal pure returns (uint256) {
        uint256 result = 1;
        while (exp > 0) {
            if (exp % 2 == 1) result = mulmod(result, base, p);

            base = mulmod(base, base, p);
            exp /= 2;
        }
        return result;
    }

    function orderOfPoint() internal {}
    function scalarMultiply() internal {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 *  @title Elliptic Curve Operations on secp256k1 (used in Bitcoin, Ethereum).
 *  @notice Provides core elliptic curve functions for secp256k1: point negation, addition, doubling, scalar multiplication, and validation.
 *  @dev Curve equation: y² = x³ + 7 over field F_p, where p = 2²⁵⁶ − 2³² − 977.
 *  @dev Reference: https://en.bitcoin.it/wiki/Secp256k1
 */
library Secp256k1 {
    /// @dev Thrown when a given (x, y) coordinate pair is not on the secp256k1 curve.
    error Secp256k1__InvalidPoint(uint256 x, uint256 y);
    /// @dev Thrown when a coordinate (x or y) exceeds the field modulus p.
    error Secp256k1__InvalidCoordinate(uint256 coordinate);

    /// @dev Curve coefficient a in the equation y² = x³ + ax + b. For secp256k1, a = 0.
    uint256 constant a = 0;
    /// @dev Curve coefficient b in the equation y² = x³ + ax + b. For secp256k1, b = 7.
    uint256 constant b = 7;
    /// @dev Prime field modulus p = 2²⁵⁶ − 2³² − 977. Defines the finite field F_p for secp256k1.
    uint256 constant p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    /// @dev The order (n) of the secp256k1 elliptic curve group.
    uint256 constant SECP256K1_ORDER = 115792089237316195423570985008687907852837564279074904382605163141518161494337;

    /**
     *  @notice Ensures that a point (x, y) is either on the secp256k1 curve or is the point at infinity.
     *  @dev Point at infinity is considered valid in this implementation.
     *  @dev Reverts with `Secp256k1__InvalidPoint` if the point is not valid.
     *  @param x The x-coordinate of the point.
     *  @param y The y-coordinate of the point.
     *  @custom:error Secp256k1__InvalidPoint Thrown if (x, y) is not on the curve and not the point at infinity.
     */
    modifier onlyValidPoint(uint256 x, uint256 y) {
        if (!isOnCurve(x, y) && !isInfinity(x, y)) revert Secp256k1__InvalidPoint(x, y);
        _;
    }

    /**
     *  @notice Checks whether the given point (x, y) is the point at infinity.
     *  @dev In this implementation, (0, 0) is treated as the point at infinity.
     *  @param x The x-coordinate of the point.
     *  @param y The y-coordinate of the point.
     *  @return True if the point is (0, 0), false otherwise.
     */
    function isInfinity(uint256 x, uint256 y) internal pure returns (bool) {
        return x == 0 && y == 0;
    }

    /**
     *  @notice Checks if a point (x, y) lies on the secp256k1 curve.
     *  @dev The curve equation is y² ≡ x³ + 7 (mod p). This function verifies if the point satisfies this equation.
     *  @dev Reverts with `Secp256k1__InvalidCoordinate` if the coordinates exceed the field modulus p.
     *  @dev Point at infinity (0,0) is not considered on curve in this implementation.
     *  @param x The x-coordinate of the point.
     *  @param y The y-coordinate of the point.
     *  @return True if the point (x, y) is on the secp256k1 curve, false otherwise.
     *  @custom:error Secp256k1__InvalidCoordinate Thrown if the coordinate is greater than or equal to the modulus p.
     */
    function isOnCurve(uint256 x, uint256 y) internal pure returns (bool) {
        if (x >= p) revert Secp256k1__InvalidCoordinate(x);
        if (y >= p) revert Secp256k1__InvalidCoordinate(y);

        uint256 leftHandSide = mulmod(y, y, p); // y² mod p
        uint256 rightHandSide = addmod(mulmod(x, mulmod(x, x, p), p), 7, p); // (x³ + 7) mod p
        return leftHandSide == rightHandSide;
    }

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! NEGATE POINT
    // ! -----------------------------------------------------------------------------------------------------------------------
    /**
     *  @notice Negates a point (x, y) on the secp256k1 curve.
     *  @dev This function uses the `onlyValidPoint` modifier to ensure that the point (x, y) is valid (on curve or at infinity) before negation.
     *  @dev If the point is at infinity (0,0), it returns (0,0).
     *  @param x The x-coordinate of the point.
     *  @param y The y-coordinate of the point.
     *  @return The negated point (x, p - y), or (0, 0) if the point is at infinity.
     *  @custom:error Secp256k1__InvalidPoint Thrown if (x, y) is not on the curve and not the point at infinity.
     *  @custom:error Secp256k1__InvalidCoordinate Thrown if the coordinate is greater than or equal to the modulus p.
     */
    function negatePoint(uint256 x, uint256 y) internal pure onlyValidPoint(x, y) returns (uint256, uint256) {
        if (isInfinity(x, y)) return (0, 0);
        return negatePointUnchecked(x, y);
    }

    /**
     *  @notice Negates a point (x, y) on the secp256k1 curve without any validation.
     *  @dev This function does not use any validation checks.
     *  @dev This function assumes the point (x, y) is valid, lies on curve and is NOT the point at infinity (0,0).
     *  @dev Do NOT use this function for points that are not on curve. Do not use for point at infinity.
     *  @param x The x-coordinate of the point.
     *  @param y The y-coordinate of the point.
     *  @return The negated point (x, p - y).
     */
    function negatePointUnchecked(uint256 x, uint256 y) internal pure returns (uint256, uint256) {
        return (x, p - y);
    }

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! ADD POINTS
    // ! -----------------------------------------------------------------------------------------------------------------------
    /**
     *  @notice Adds two points on the secp256k1 curve.
     *  @dev Uses the `onlyValidPoint` modifier to ensure that both input points are valid (on the curve or at infinity).
     *  @dev Formula:
     *      If P = (x1, y1) and Q = (x2, y2), then:
     *      m = (y2 - y1) / (x2 - x1) (mod p) where p is the field modulus.
     *      x3 = m² - x1 - x2 (mod p)
     *      y3 = m * (x1 - x3) - y1 (mod p)
     *  @param x1 The x-coordinate of the first point.
     *  @param y1 The y-coordinate of the first point.
     *  @param x2 The x-coordinate of the second point.
     *  @param y2 The y-coordinate of the second point.
     *  @return (x3, y3) The resulting point after addition.
     *  @custom:error Secp256k1__InvalidPoint Thrown if (x, y) pair is not on the curve and not the point at infinity.
     *  @custom:error Secp256k1__InvalidCoordinate Thrown if the coordinate is greater than or equal to the modulus p.
     */
    function addPoints(uint256 x1, uint256 y1, uint256 x2, uint256 y2)
        internal
        pure
        onlyValidPoint(x1, y1)
        onlyValidPoint(x2, y2)
        returns (uint256, uint256)
    {
        return addPointsUnchecked(x1, y1, x2, y2);
    }

    /**
     *  @notice Adds two points on the secp256k1 curve without performing validation.
     *  @dev Assumes that both input points are valid (on the curve or at infinity).
     *  @dev Do NOT use this function for points that are not valid.
     *  @dev Returns the other point if one of the points is at infinity.
     *  @dev Returns (0, 0) if the points are additive inverses (i.e., a point and its negation).
     *  @dev Formula:
     *      If P = (x1, y1) and Q = (x2, y2), then the slope `m` is calculated as:
     *      m = (y2 - y1) / (x2 - x1) (mod p) where p is the field modulus.
     *      x3 = m² - x1 - x2 (mod p)
     *      y3 = m * (x1 - x3) - y1 (mod p)
     *  @param x1 The x-coordinate of the first point.
     *  @param y1 The y-coordinate of the first point.
     *  @param x2 The x-coordinate of the second point.
     *  @param y2 The y-coordinate of the second point.
     *  @return (x3, y3) The resulting point after addition.
     */
    function addPointsUnchecked(uint256 x1, uint256 y1, uint256 x2, uint256 y2)
        internal
        pure
        returns (uint256, uint256)
    {
        if (isInfinity(x1, y1)) return (x2, y2);
        if (isInfinity(x2, y2)) return (x1, y1);

        if (x1 == x2) {
            if (y1 == y2) return doublePointUnchecked(x1, y1); // Doubling a point
            if ((y1 + y2) % p == 0) return (0, 0); // Return point at infinity
        }

        // Calculate slope
        uint256 numerator = addmod(y2, p - y1, p);
        uint256 denominator = addmod(x2, p - x1, p);
        uint256 m = mulmod(numerator, modInverse(denominator), p);

        // ! x3 = m² - x1 - x2 (mod p) = m² - (x1 + x2) (mod p)
        uint256 x3 = addmod(mulmod(m, m, p), p - addmod(x1, x2, p), p);
        // ! y3 = m * (x1 - x3) - y1 mod p
        uint256 y3 = addmod(mulmod(m, addmod(x1, p - x3, p), p), p - y1, p);

        return (x3, y3);
    }

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! POINT DOUBLING
    // ! -----------------------------------------------------------------------------------------------------------------------

    /**
     *  @notice Doubles a point on the secp256k1 curve.
     *  @dev Uses the `onlyValidPoint` modifier to ensure that the input point is valid (on the curve or at infinity).
     *  @dev If the point is at infinity (0,0), it returns (0,0).
     *  @dev Formula for point doubling:
     *      If P = (x1, y1), then:
     *      m = (3 * x1²) / (2 * y1) (mod p) where p is the field modulus.
     *      x3 = m² - 2 * x1 (mod p)
     *      y3 = m * (x1 - x3) - y1 (mod p)
     *  @param x The x-coordinate of the point.
     *  @param y The y-coordinate of the point.
     *  @return (x3, y3) The resulting point after doubling.
     *  @custom:error Secp256k1__InvalidPoint Thrown if (x, y) is not on the curve and not the point at infinity.
     *  @custom:error Secp256k1__InvalidCoordinate Thrown if the coordinate is greater than or equal to the modulus p.
     */
    function doublePoint(uint256 x, uint256 y) internal pure onlyValidPoint(x, y) returns (uint256, uint256) {
        if (isInfinity(x, y)) return (0, 0);
        return doublePointUnchecked(x, y);
    }

    /**
     *  @notice Doubles a point on the secp256k1 curve without performing validation.
     *  @dev Assumes that the point (x, y) is valid (on the curve and not at infinity).
     *  @dev Do NOT use this function for point that is not valid.
     *  @dev If the point is at infinity (0,0), it returns (0,0).
     *  @dev Formula for point doubling:
     *      If P = (x1, y1), then:
     *      m = (3 * x1²) / (2 * y1) (mod p) where p is the field modulus.
     *      x3 = m² - 2 * x1 (mod p)
     *      y3 = m * (x1 - x3) - y1 (mod p)
     *  @param x1 The x-coordinate of the point.
     *  @param y1 The y-coordinate of the point.
     *  @return (x3, y3) The resulting point after doubling.
     */
    function doublePointUnchecked(uint256 x1, uint256 y1) internal pure returns (uint256, uint256) {
        //  (3 * x1²) (mod p)
        uint256 numerator = mulmod(3, mulmod(x1, x1, p), p);
        // (2 * y1) (mod p)
        uint256 denominator = mulmod(2, y1, p);
        uint256 m = mulmod(numerator, modInverse(denominator), p);

        // ! x3 = m² - 2 * x1 (mod p)
        uint256 x3 = addmod(mulmod(m, m, p), p - addmod(x1, x1, p), p);
        // ! y3 = m * (x1 - x3) - y1 (mod p)
        uint256 y3 = addmod(mulmod(m, addmod(x1, p - x3, p), p), p - y1, p);

        return (x3, y3);
    }

    // ! -----------------------------------------------------------------------------------------------------------------------
    // ! SCALAR MULTIPLICATION
    // ! -----------------------------------------------------------------------------------------------------------------------
    /**
     *  @notice Performs scalar multiplication on a point (x, y) on the secp256k1 curve.
     *  @dev This function calculates the result of multiplying the point (x, y) by a scalar value.
     *  @dev Uses the double-and-add method to perform the scalar multiplication efficiently.
     *  @dev If the point is at infinity (0,0), it returns (0,0).
     *  @dev If `scalar` is 0, it returns (0,0)
     *  @param x The x-coordinate of the point.
     *  @param y The y-coordinate of the point.
     *  @param scalar The scalar value by which to multiply the point.
     *  @return (x, y) The resulting point after scalar multiplication.
     *  @custom:error Secp256k1__InvalidPoint Thrown if (x, y) is not on the curve and not the point at infinity.
     *  @custom:error Secp256k1__InvalidCoordinate Thrown if the coordinate is greater than or equal to the modulus p.
     */
    function scalarMultiplication(uint256 x, uint256 y, uint256 scalar)
        internal
        pure
        onlyValidPoint(x, y)
        returns (uint256, uint256)
    {
        if (isInfinity(x, y)) return (0, 0);

        (uint256 resX, uint256 resY) = (0, 0);
        (uint256 currX, uint256 currY) = (x, y);

        while (scalar > 0) {
            if (scalar & 1 == 1) {
                (resX, resY) = addPointsUnchecked(resX, resY, currX, currY);
            }
            (currX, currY) = doublePointUnchecked(currX, currY);
            scalar >>= 1;
        }
        return (resX, resY);
    }

    /**
     *  @notice Calculates the modular inverse of a number modulo p.
     *  @dev Uses Fermat's Little Theorem to compute the modular inverse as `a^(p-2) mod p`.
     *  @param toInvert The number for which the modular inverse is to be computed.
     *  @return The modular inverse of `toInvert` mod p.
     */
    function modInverse(uint256 toInvert) internal pure returns (uint256) {
        return modPow(toInvert, p - 2);
    }

    /**
     *  @notice Performs modular exponentiation.
     *  @dev Computes base^exp mod p efficiently using binary exponentiation (exponentiation by squaring).
     *  @param base The base value to be exponentiated.
     *  @param exp The exponent to which the base is raised.
     *  @return The result of base^exp (mod p).
     */
    function modPow(uint256 base, uint256 exp) internal pure returns (uint256) {
        uint256 result = 1;
        while (exp > 0) {
            if (exp % 2 == 1) result = mulmod(result, base, p);

            base = mulmod(base, base, p);
            exp /= 2;
        }
        return result;
    }
}

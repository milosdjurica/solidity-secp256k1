// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Secp256k1 {
    // Curve parameters for secp256k1
    uint256 constant a = 0;
    uint256 constant b = 7;
    // p = 2^256 - 2^32 - 977
    uint256 constant p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    function isOnCurve() internal {}
    function isInfinity() internal {}
    function addPoint() internal {}
    function negatePoint() internal {}
    function orderOfPoint() internal {}
    function scalarMultiply() internal {}
}

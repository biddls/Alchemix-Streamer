// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title BitOps
/// @author Biddls
/// @notice A library for specific bit operations
/// @dev Intended for StreamPay Use only
library BitOps {
    /// @notice Gets bit value at position
    /// @param a bytes2 of data
    /// @param n index of bit
    /// @return Returns the state of the bit
    function getBit(bytes2 a, uint16 n) external pure returns (bool) {
        return a & bytes2(uint16(2)**n) != 0;
    }

    /// @notice Set bit value at position into state "true"
    /// @param a bytes2 of data
    /// @param n index of bit
    /// @return Returns the now updated bytes2
    function setBit(bytes2 a, uint16 n) external pure returns (bytes2) {
        return a | bytes2(uint16(2)**n);
    }
    /// @notice Set bit value at position into state "false"
    /// @param a bytes2 of data
    /// @param n index of bit
    /// @return Returns the now updated bytes2
    function clearBit(bytes2 a, uint16 n) external pure returns (bytes2) {
        return a & (bytes2(uint16(2)**n) ^ 0xffff);
    }
}
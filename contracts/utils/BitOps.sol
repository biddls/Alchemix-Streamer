// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library BitOps {
    function negate(bytes2 a) public pure returns (bytes2) {
        return a ^ allOnes();
    }
    function shiftLeft(bytes2 a, uint16 n) public pure returns (bytes2) {
        return bytes2(uint16(uint16(a) * (2 ** n)));
    }
    function shiftRight(bytes2 a, uint16 n) public pure returns (bytes2) {
        return bytes2(uint16(uint16(a) / 2 ** n));
    }
    function getFirstN(bytes2 a, uint16 n) external pure returns (bytes2) {
        return a & shiftLeft(bytes2(uint16(2 ** n - 1)), 16 - n);
    }
    function getLastN(bytes2 a, uint16 n) external pure returns (bytes2) {
        return bytes2(uint16(uint16(a) % 2 ** n));
    }
    // Sets all bits to 1
    function allOnes() public pure returns (bytes2) {
        return bytes2(0xffff); // 0 - 1, since data type is unsigned, this results in all 1s.
    }
    // Get bit value at position
    function getBit(bytes2 a, uint16 n) external pure returns (bool) {
        return a & shiftLeft(0x0001, n) != 0;
    }
    // Set bit value at position
    function setBit(bytes2 a, uint16 n) external pure returns (bytes2) {
        return a | shiftLeft(0x0001, n);
    }
    // Set the bit into state "false"
    function clearBit(bytes2 a, uint16 n) external pure returns (bytes2) {
        return a & negate(shiftLeft(0x0001, n));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {BitOps} from "./utils/BitOps.sol";

contract SimpleSummedArrays{

    /// @dev unix time since last drawDown
    uint256 public sinceLast;
    /// @dev mapping index => Queue
    mapping(uint16 => uint256) public sinceLastData;
    mapping(uint16 => uint256) public CPSData;
    /// @dev maximum search distance
    uint8 immutable public maxSteps;
    /// @dev array of addresses for the deploying contract and the owner of the stream
    address[2] public admins;

    constructor(uint8 _maxSteps, address[2] memory _admins){
        maxSteps = _maxSteps;
        admins = _admins;
        sinceLast = block.timestamp;
    }

    function calcReserved(
        uint16 _nubIndex,
        bool updating
    ) external adminsOnly maxSizeCheck(_nubIndex)
    returns (uint256) {
        require(block.timestamp > sinceLast);
        return _calcReserved(_nubIndex, updating);
    }

    function _calcReserved(
        uint16 _nubIndex,
        bool updating
    ) internal
    returns (uint256 total) {
        uint256 now = block.timestamp;
        for(uint16 i = _nubIndex; i >= 0; i--) {
            total += (now - sinceLastData[i]) * CPSData[i];
            if(updating) {
                sinceLastData[i] = now;
            }
        }
        return total;
    }

    function write(
        uint16 _nubIndex,
        uint256 _posChange,
        uint256 _negChange,
        uint256 init // is recommended you also do a draw down at the same time as this
    // so you can just leave init as 0 so it defaults to now
    ) external adminsOnly maxSizeCheck(_nubIndex){
        CPSData[_nubIndex] = CPSData[_nubIndex] + _posChange - _negChange;
        if (init != 0) {
            sinceLastData[_nubIndex] = init;
        } else {
            sinceLastData[_nubIndex] = block.timestamp;
        }
    }

    function clear(
        uint16 _nubIndex
    ) external adminsOnly maxSizeCheck(_nubIndex){
        delete CPSData[_nubIndex];
        delete sinceLastData[_nubIndex];
    }

    modifier adminsOnly {
        require(admins[0] == msg.sender || admins[1] == msg.sender, "Admins only");
        _;
    }

    function swap(uint16 index1, uint16 index2) external {
        uint256 temp = sinceLastData[index1];
        sinceLastData[index1] = sinceLastData[index2];
        sinceLastData[index2] = temp;
        temp = CPSData[index1];
        CPSData[index1] = CPSData[index2];
        CPSData[index2] = temp;
    }

    modifier maxSizeCheck(uint16 _numb) {
        require(_numb < maxSteps, "Index out of bounds");
        _;
    }

    function selfDes(
    ) adminsOnly public {
        // should be the user account is admins[0]
        selfdestruct(payable(address(admins[0])));
    }
}
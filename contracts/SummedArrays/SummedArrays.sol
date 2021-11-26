// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {BitOps} from "./../utils/BitOps.sol";
//import {console} from "hardhat/console.sol";

contract SummedArrays{

    /// @dev mapping index => Queue
    mapping(uint16 => uint256) public data;
    /// @dev maximum search distance
    uint8 immutable public maxSteps;
    /// @dev array of addresses for the deploying contract and the owner of the stream
    address[2] public admins;

    constructor(uint8 _maxSteps, address[2] memory _admins){
        maxSteps = _maxSteps;
        admins = _admins;
    }

    function read(
        uint16 _nubIndex
    ) external view adminsOnly maxSizeCheck(_nubIndex, false)
    returns (uint256) {
        require(_nubIndex != 0, "cant access 0");
        return _read(_nubIndex);
    }

    function _read(
        uint16 _nubIndex
    ) internal view adminsOnly
    returns (uint256 total){
        if(_nubIndex == 2**(1 +maxSteps)) {
            return data[uint16(2**(1 +maxSteps))];
        }
        // converts to bit array
        bytes2 _index = bytes2(_nubIndex);
        total = 0;
        // counts from right to left as far as it can step (last index to 15-maxSteps)
        for(uint8 i = 0; i <= maxSteps; i++){
            // if there is a 1 there
            if (BitOps.getBit(_index, i) == true){
                // gets data and adds it to total
                total += data[uint16(_index)];
                _index = BitOps.clearBit(_index, i);
            }
        }
    }

    function write(
        uint16 _nubIndex,
        uint256 _posChange,
        uint256 _negChange
    ) external adminsOnly maxSizeCheck(_nubIndex, true) returns (bool){
        require(_nubIndex != 0, "cant get 0");
        return _write(_nubIndex, _posChange, _negChange);
    }

    function _write(
        uint16 _nubIndex,
        uint256 _posChange,
        uint256 _negChange
    ) internal adminsOnly returns (bool){ // returns true if the array is empty
        /*
        using bit shifting you can then use an AND function on the data to get the next index
        */
        data[_nubIndex] = updatePoint(data[_nubIndex], _posChange, _negChange);

        // converts to bit array
        bytes2 _index = bytes2(_nubIndex);
        for (uint8 i = 1; i <= maxSteps + 1; i++){

            if(BitOps.getBit(_index, i-1) == true && BitOps.getBit(_index, i) == false){
                _index = BitOps.clearBit(_index, i-1);
                _index = BitOps.setBit(_index, i);
                data[uint16(_index)] = data[uint16(_index)] + _posChange - _negChange;
            } else {
                _index = BitOps.clearBit(_index, i-1);
            }
        }
        if(data[uint16(2**(maxSteps + 1))] == 0){return true;}
        return false;
    }

    function updatePoint(
        uint256 _data,
        uint256 _pos,
        uint256 _neg
    ) internal pure returns (uint256){
        require((_pos != 0) != (_neg != 0), "one value has to be 0");
        require(_data >= _neg, "cant underflow");
        return _data + _pos - _neg;
    }

    function max(
    ) external view returns (uint256){
        return _read(uint16(2**(1 + maxSteps)));
    }

    function clear(
        uint16 _nubIndex
    ) external adminsOnly maxSizeCheck(_nubIndex, true) returns (bool){
        return _write(_nubIndex, 0, _read(_nubIndex) - _read(_nubIndex - 1));
    }

    modifier adminsOnly {
        require(admins[0] == msg.sender || admins[1] == msg.sender, "Admins only");
        _;
    }

    function _maxSizeCheck(
        uint16 _numb,
        bool _writing
    ) maxSizeCheck(_numb, _writing) internal {}

    function swap(uint16 index1, uint16 index2) external {
        require(index1 < index2, "incorrect ordering");
        require(index1 >= 1, "no 0s");
        uint256 numb1 = index1 == 0 ? _read(index1) : _read(index1) - _read(max(index1 - 1, 1));
        uint256 numb2 = _read(index2) - _read(index2 - 1);
        _write(index1, numb2, numb1);
        _write(index2, numb1, numb2);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint16 a, uint16 b) internal pure returns (uint16) {
        return a >= b ? a : b;
    }

    modifier maxSizeCheck(uint16 _numb, bool _writing) {
        if(_writing){
            require(_numb < 2**(1 + maxSteps), "Numb to big");
        } else {
            require(_numb <= 2**(1 + maxSteps), "Numb to big");
        }
        _;
    }

    function selfDes() adminsOnly public {
        selfdestruct(payable(address(admins[0])));
    }
}
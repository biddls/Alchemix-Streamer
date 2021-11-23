// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {BitOps} from "./utils/BitOps.sol";
//import {console} from "hardhat/console.sol";

contract SummedArrays{

    /// @dev mapping index => Queue
    mapping(uint16 => uint256) public data;
    /// @dev maximum search distance
    uint8 immutable public maxSteps;
    /// @dev array of addresses for the deploying contract and the owner of the stream
    address[2] public admins;
    /// @dev
    uint16[] public next;

    constructor(uint8 _maxSteps, address[2] memory _admins){
        maxSteps = _maxSteps;
        admins = _admins;
        next.push(0);
    }

    function read(
        uint16 _nubIndex
    ) external view adminsOnly maxSizeCheck(_nubIndex, false)
    returns (uint256) {
        return _read(_nubIndex);
    }

    function _read(
        uint16 _nubIndex
    ) internal view adminsOnly
    returns (uint256 total){
        if(_nubIndex == 0){
            return data[0];
        } else if(_nubIndex == 2**(1 +maxSteps)) {
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
    ) external adminsOnly maxSizeCheck(_nubIndex, true) {
        _write(_nubIndex, _posChange, _negChange);
    }

    function newData(
        uint256 _value
    ) external adminsOnly {
        uint16 _index = _pop(next);
        _maxSizeCheck(_index, true);
        _write(_index, _value, 0);
        if(next.length == 0){
            next.push(_index + 1);
        }
    }

    function _write(
        uint16 _nubIndex,
        uint256 _posChange,
        uint256 _negChange
    ) internal adminsOnly returns (bool){
        /*
        using bit shifting you can then use an AND function on the data to get the next index
        */
        data[_nubIndex] = data[_nubIndex] + _posChange - _negChange;
        if(_nubIndex == 0){
            _nubIndex = 1;
            data[_nubIndex] = data[_nubIndex] + _posChange - _negChange;
        }
        // converts to bit array
        bytes2 _index = bytes2(_nubIndex);
        for (uint8 i = 1; i <= maxSteps + 1; i++){

/* testing //
            logBytes(_index);
            console.log(BitOps.getBit(_index, i-1) == true, BitOps.getBit(_index, i) == false);
*/

            if(BitOps.getBit(_index, i-1) == true && BitOps.getBit(_index, i) == false){
                _index = BitOps.clearBit(_index, i-1);
                _index = BitOps.setBit(_index, i);
                data[uint16(_index)] = data[uint16(_index)] + _posChange - _negChange;
            } else {
                _index = BitOps.clearBit(_index, i-1);
            }
        }
        data[uint16(2**(maxSteps + 1))] = data[uint16(2**(maxSteps + 1))] + _posChange - _negChange;
        if(data[uint16(2**(maxSteps + 1))] == 0){return true;}
        return false;
    }

/*
    function logBytes(bytes2 _data) public {
        string memory _temp = new string(16);
        for (uint8 i = 0; i < 16; i++){
            _temp = _stringReplace(_temp, i, BitOps.getBit(_data, i) ? "1" : "0");
        }
        console.log(_temp);
    }

    function _stringReplace(string memory _string, uint256 _pos, string memory _letter) internal pure returns (string memory) {
        bytes memory _stringBytes = bytes(_string);
        bytes memory result = new bytes(_stringBytes.length);

        for(uint i = 0; i < _stringBytes.length; i++) {
            result[i] = _stringBytes[i];
            if(i==_pos)
                result[i]=bytes(_letter)[0];
        }
        return string(result);
    }
*/

    function max(
    ) external view returns (uint256){
        return _read(uint16(2**(1 + maxSteps)));
    }

    function clear(
        uint16 _nubIndex
    ) external adminsOnly maxSizeCheck(_nubIndex, true) returns (bool){
        _write(_nubIndex, 0, _read(_nubIndex));
        next.push(_nubIndex);
        return true;
    }

    modifier adminsOnly {
        require(admins[0] == msg.sender || admins[1] == msg.sender, "Admins only");
        _;
    }

    function _maxSizeCheck(
        uint16 _numb,
        bool _writing
    ) maxSizeCheck(_numb, _writing) internal {}

    function _pop(uint16[] storage _array) internal returns (uint16 _item){
        _item = _array[_array.length-1];
        _array.pop();
        return _item;
    }

    function swap(uint16 index1, uint16 index2) external {
        uint256 numb1 = _read(index1);
        uint256 numb2 = _read(index2);
        _write(index1, numb2, numb1);
        _write(index2, numb1, numb2);
    }

    modifier maxSizeCheck(uint16 _numb, bool _writing) {
        if(_writing){
            require(_numb < 2**(1 + maxSteps), "Numb to big");
        } else {
            require(_numb <= 2**(1 + maxSteps), "Numb to big");
        }
        _;
    }

    function selfDes(
    ) adminsOnly public {
        selfdestruct(payable(address(admins[0])));
    }
}
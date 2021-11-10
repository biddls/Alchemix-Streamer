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

    constructor(uint8 _maxSteps, address[2] memory _admins){
        maxSteps = _maxSteps;
        admins = _admins;
    }

    function read(
        uint16 _nubIndex
    ) external view adminsOnly maxSizeCheck(_nubIndex)
    returns (uint256 total){
        if(_nubIndex == 0){return data[0];}
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
    ) external adminsOnly maxSizeCheck(_nubIndex) {
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
    modifier adminsOnly {
        require(admins[0] == msg.sender || admins[1] == msg.sender, "Admins only");
        _;
    }

    modifier maxSizeCheck(uint16 _numb) {
        require(_numb < 2**(1 +maxSteps), "Numb to big");
        _;
    }
}
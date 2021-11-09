// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// I sense that there will be a billion 1 off errors

contract SummedArrays {

    /// @dev mapping index => Queue
    mapping(uint16 => uint256) public data;
    /// @dev maximum search distance
    uint8 immutable public maxSteps;
    /// @dev at what rate it goes up by (maxSteps ^ stepSize = max size of array)
    uint8 immutable public stepSize;
    /// @dev array of addresses for the deploying contract and the owner of the stream
    address[2] public admins;

    constructor(uint8 _maxSteps, uint8 _stepSize, address[2] memory _admins){
        maxSteps = _maxSteps;
        stepSize = _stepSize;
        admins = _admins;
    }

    function read(uint16 _index) view adminsOnly maxSizeCheck(_index) returns (uint256 total){
        // converts to bit array
        bytes2 _index = bytes2(_index);
        // init vars
        uint256 summedIndex;
        total = 0;
        // counts from right to left as far as it can step (last index to 15-maxSteps)
        for(uint8 i = 15; i >= 15 - maxSteps; i--){
            // if there is a 1 there
            if (_index[i] == 1){
                // calculates where to next get data from
                summedIndex += (15 - i)**2;
                // gets data and adds it to total
                total += data[summedIndex].sinceLast;
            }
        }
    }

    /*
    using bit shifting you can then use an AND function on the data to get the next index
    */

    function write(uint16 _index, uint256 _posChange) external adminsOnly maxSizeCheck(_index) {
        // converts to bit array
        bytes2 _index = bytes2(_index);
        // for identifying the last 0 before the LSB
        bool last0LSB;
        for (uint8 i = 14; i >= 15 - maxSteps; i--){
            if(_index[i-1] == 1 && _index[i] == 0){
                data[_index] += _posChange;
                _index[i-1] = 0;
                _index[i] = 1;
            } else {
                _index[i-1] = 0;
            }
        }
    }

    modifier adminsOnly {
        require(admins[0] == msg.sender || admins[1] == msg.sender, "Admins only");
        _;
    }

    modifier maxSizeCheck(uint16 _numb) {
        require(_numb < 2**maxSteps);
        _;
    }
}
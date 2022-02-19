// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract SimpleSummedArrays{

    /// @dev unix time since last drawDown
    uint256 public sinceLast;
    /// @dev mapping index => Queue
    mapping(uint16 => uint256) public sinceLastData;
    mapping(uint16 => uint256) public CPSData;
    /// @dev maximum search distance
    uint8 immutable public maxIndex;
    /// @dev array of addresses for the deploying contract and the owner of the stream
    address[2] public admins;

    constructor(uint8 _maxIndex, address[2] memory _admins){
        maxIndex = _maxIndex + 1;
        admins = _admins;
        sinceLast = block.timestamp;
    }

    function calcReserved(
        uint8 _nubIndex
    ) external adminsOnly maxSizeCheck(_nubIndex, false)
    returns (uint256 total) {
        require(block.timestamp > sinceLast);
//        uint256 now = block.timestamp;
        for(uint16 i = 0; i <= _nubIndex; i++) {
            total = total + ((block.timestamp - sinceLastData[i]) * CPSData[i]);
        }
        emit calcRes(total);
        return total;
    }

    function updateSinceLast(
        uint8 _nubIndex
    ) external adminsOnly maxSizeCheck(_nubIndex, true) {
        sinceLastData[_nubIndex] = block.timestamp;
    }

    function write(
        uint8 _nubIndex,
        uint256 _posCPSChange,
        uint256 _negCPSChange,
        uint256 init
    // it is recommended you also do a draw down at the same time
    // as this so you can just leave init as 0 so it defaults to now
    ) external adminsOnly maxSizeCheck(_nubIndex, true){
        // updates internal data
        CPSData[_nubIndex] = CPSData[_nubIndex] + _posCPSChange - _negCPSChange;
        // if init is 0 then just set since last to now
        sinceLastData[_nubIndex] = init == 0 ? block.timestamp : init;
    }

    function clear(
        uint8 _nubIndex
    ) external adminsOnly maxSizeCheck(_nubIndex, true){
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

    modifier maxSizeCheck(uint8 _numb, bool _writing) {
        if (_writing) {
            require(_numb < maxIndex, "Index out of bounds");
        } else {
            require(_numb <= maxIndex, "Index out of bounds");
        }
        _;
    }

    function selfDes(
    ) adminsOnly public {
        // should be the user account is admins[0]
        selfdestruct(payable(address(admins[0])));
    }

    event calcRes(
        uint256 amountReserved
    );
}
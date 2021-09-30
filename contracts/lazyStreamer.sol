// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// this contract allows for external users to keep track of who is going next
// its way more gas costly but if its on an L2 then people dont care as much
// and allows keepers to be way lazier when calling the code
// each address can deploy their own streaming contract

contract lazyStreamer {

    address public peepoPay;
    address public admin;

    mapping(uint256 => Queue) dayQueue;
    uint256 public firstDay;
    uint256 public lastDay;
    /*
    keeps track of when it was last called so it can
    make sure that it doesn't call the draw down function
    5 times to catch up in case it falls behind it will
    write un-drained streams to the current day
    (block.timestamp - sinceLast) / 86400
    */
    uint256 public sinceLast;
    uint256 public created;

    // holds a queue of IDs
    struct Queue{
        // list of IDs to be drawn down on that day
        mapping(uint256 => uint256) IDs;
        // pointers
        uint256 first;
        uint256 last;
    }

    constructor(address _peepoPay) {
        admin = msg.sender;
        created = block.timestamp;
        peepoPay = _peepoPay;
    }

    function pushStreams(uint256 _dayNo, uint256[] memory _ids) external {
        require(msg.sender == admin);
        require(_dayNo >= firstDay);
        for(uint256 i; i<_ids.length; i++){
            _pushStream(_dayNo, _ids[i]);
        }
    }

    function pushStream(uint256 _dayNo, uint256 _id) external {
        require(msg.sender == admin);
        require(_dayNo >= firstDay);
        _pushStream(_dayNo, _id);
    }

    function _pushStream(uint256 _dayNo, uint256 _id) internal {
        // assigns the ID of the stream in the next available slot
        dayQueue[_dayNo].IDs[dayQueue[_dayNo].last] = _id;
        // updates the position of the pointer
        dayQueue[_dayNo].last++;
        // updates the bounds for the day queue
        lastDay = _dayNo >= lastDay ? _dayNo++ : lastDay;
    }

    // may be able to run out of gas and crash the code
    function pop() external returns (uint256 ID) {
        require(msg.sender == admin || msg.sender == address(this), "not admin");
        // if the day has data call it
        if (dayQueue[firstDay].first < dayQueue[firstDay].last && firstDay <= lastDay) { // if there is a day
            // gets the indexes for the queue of that day
            uint256 _first = dayQueue[firstDay].first;
            uint256 _last = dayQueue[firstDay].last;
            // gets the ID number
            uint256 _id = dayQueue[firstDay].IDs[_first];
            // clear data
            delete dayQueue[firstDay].IDs[_first];
            // update pointers
            dayQueue[firstDay].first++;
            return _id;
        } else {
            //clear data
            delete dayQueue[firstDay];
            // tells it to move onto the next day
            firstDay++;
            // calls the same function again searching for the next day to use
            return firstDay < lastDay ? this.pop() : 2^256-1;
        }
    }

    function removeStream(uint256 _dayNo, uint256 _IDIndex) external {
        require(msg.sender == admin);
        require(_dayNo >= firstDay);
        // set it to max ID deffo wont cause an issue later...
        // cant delete the index as it will return 0 so the 0 ID stream will get screwed
        dayQueue[_dayNo].IDs[_IDIndex] = (2^256 - 1);
    }
}
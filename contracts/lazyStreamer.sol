// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {Istreamer} from "./interfaces/Istreamer.sol";

// this contract allows for external users to keep track of who is going next
// its way more gas costly but if its on an L2 then people dont care as much
// and allows keepers to be way lazier when calling the code
// each address can deploy their own streaming contract

contract lazyStreamer {

    address public streamerAddr;
//    address public admin;

    mapping(uint256 => Queue) dayQueue;
    uint256 firstDay;
    uint256 lastDay;

    // holds a queue of IDs
    struct Queue{
        // list of IDs to be drawn down on that day
        mapping(uint256 => uint256) IDs;
        // pointers
        uint256 first;
        uint256 last;
    }

    function pushStreams(address _payer, uint256 _dayNo, uint256[] memory _ids) external {
//        require(_payer == admin);
        require(_dayNo >= firstDay);
        for(uint256 i; i<_ids.length; i++){
            // gets the queue for the day // gets the next spot on the queue then fills that spot int
            dayQueue[_dayNo].IDs[dayQueue[_dayNo].last] = _ids[i];
            // gets the same queue as above and increments the pointer to the next position
            dayQueue[_dayNo].IDs[dayQueue[_dayNo].last]++;
        }
    }

    function pop() internal returns (uint256 ID) {
//        require(_payer == admin);
        // if the next day is empty try the next day
        if(dayQueue[firstDay].first == dayQueue[firstDay].last) {
            // make sure that there is a day
            require(firstDay < lastDay);
            //clear data
            delete dayQueue[firstDay];
            // tells it to move onto the next day
            firstDay++;
            // calls the same function again searching for the next day to use
            return pop();
        } else { // if there is a day
            // gets the indexes for the queue of that day
            uint256 _first = dayQueue[firstDay].first;
            uint256 _last = dayQueue[firstDay].last;
            // if there is data in the day
            if(_first < _last){
                // update pointers
                dayQueue[firstDay].first++;
                // gets the ID number
                uint256 _id = dayQueue[firstDay].IDs[_first];
                // clear data
                delete dayQueue[firstDay].IDs[_first];
                return _id;
            } else {
                // there is no data left in that day number
                if(firstDay < lastDay){
                    // deletes the day
                    delete dayQueue[firstDay];
                    // updates pointer
                    firstDay++;
                    // calls function again to try again
                    pop();
                } else {
                    // there are no more streams to draw down from so that's the end of it
                    revert();
                }
            }
        }
        return 1;
    }
}
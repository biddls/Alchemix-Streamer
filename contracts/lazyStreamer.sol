// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract lazyStreamer {

    // each payer gets a queue for each day
    mapping(address => DayQueue) public payerQueueLookup;
    // pointers
    uint256 first = 0;
    uint256 last = 0;

    // each day holds a queue of IDs that can be run through
    struct DayQueue{
        // list of queues representing a list of IDs to be drawn down from
        mapping(uint256 => Queue) dayQueue;
        uint256 first;
        uint256 last;
    }

    // holds a queue of IDs
    struct Queue{
        // list of IDs to be drawn down on that day
        mapping(uint256 => uint256) IDs;
        // makes sure that an ID cant be added twice
        mapping(uint256 => bool) duplicateChecker;
        // list of amounts to be drawn down with the corresponding ID on that day
        mapping(uint256 => uint256) amounts;
        // pointers
        uint256 first;
        uint256 last;
    }

    function pushStreams(address _payer, uint256 _dayNo, uint256[] memory _ids, uint256[] memory _amounts) external {
        // makes sure your not adding data to a day in thepast
        require(_dayNo >= payerQueueLookup[_payer].first);
        _addStreams(_payer, _dayNo, _ids, _amounts);
    }

    function _pushStreams(address _payer, uint256 _dayNo, uint256[] memory _ids, uint256[] memory _amounts) internal {
        // adjusts the pointers to make sure the data is kept track of
        payerQueueLookup[_payer].last = _dayNo > payerQueueLookup[_payer].last? _dayNo : payerQueueLookup[_payer].last;
        // makes sure that the data is the same length as each stream ID has to have an expected draw down amount
        require(_ids.length == _amounts.length);
        for(uint256 i;i<_ids.length;i++){
            // add something here to check the data against the streaming contract to make sure the streams exist
            // checks for duplicates
            if(payerQueueLookup[_payer].dayQueue[_dayNo].duplicateChecker[_ids[i]]){
                // if so its skipped
                continue;
            }
            // adds stream to the data
            // looks up the payer address // finds the day // finds the next point in the queue // adds data
            payerQueueLookup[_payer].dayQueue[_dayNo].IDs[payerQueueLookup[_payer].dayQueue[_dayNo].last] = _ids[i];
            payerQueueLookup[_payer].dayQueue[_dayNo].amounts[payerQueueLookup[_payer].dayQueue[_dayNo].last] = _amounts[i];
            // increments the pointer
            payerQueueLookup[_payer].dayQueue[_dayNo].last++;
        }
    }

    function _pop(address _payer) internal returns (uint256 ID, uint256 amount) {
        // gets the Queue struct number for the stream
        Queue temp = payerQueueLookup[_payer].dayQueue[payerQueueLookup[_payer].first];
        ID = temp.IDs[temp.first];
        amount = temp.amounts[temp.first];
        // makes sure that the mapping isnt empty
        if(
            payerQueueLookup[_payer].dayQueue[payerQueueLookup[_payer].first].last
            >=
            payerQueueLookup[_payer].dayQueue[payerQueueLookup[_payer].first].first){  // non-empty queue

            // empty out the struct
            delete payerQueueLookup[_payer].dayQueue[payerQueueLookup[_payer].first].IDs[temp.first];
            delete payerQueueLookup[_payer].dayQueue[payerQueueLookup[_payer].first].duplicateChecker[temp.first];
            delete payerQueueLookup[_payer].dayQueue[payerQueueLookup[_payer].first].amounts[temp.first];
            payerQueueLookup[_payer].dayQueue[payerQueueLookup[_payer].first].first++;
        } else { // if the mapping is empty
            delete payerQueueLookup[_payer].dayQueue[payerQueueLookup[_payer].first].first;
            // if there is no more left in the day move onto checking the day array
            // fuck i confused ma self
            if(payerQueueLookup[_payer].last
                >=
                payerQueueLookup[_payer].first){
                // starts a recursion
                return (_pop(_payer));
            }
        }
    }
}
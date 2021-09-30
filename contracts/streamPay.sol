// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {lazyStreamer} from "./lazyStreamer.sol";
import {IpeepoPay} from "./interfaces/IpeepoPay.sol";

// the larger version of peepopay with more management tooling
contract streamPay {

    address public peepoPayCont;

    // set up account to allow users to create a lazystreamer contract for their account
    mapping(address => lazyStreamer) public accounts;

    constructor (address _peepoPay){
        peepoPayCont = _peepoPay;
    }

    function accountCreation() external {
        /*
        creates the streamPay contract and
        assigns the mapping so that this
        contract can reference it later
        */
        accounts[msg.sender] = new lazyStreamer(peepoPayCont);
    }

    // manage permissions for the account
    // populate the lazy streamer
    function populate(uint256 _dayNo, uint256[] memory _ids) public {
        _populate(msg.sender, _dayNo, _ids);
    }

    function _populate(address _account, uint256 _dayNo, uint256[] memory _ids) internal {
        accounts[_account].pushStreams(_dayNo, _ids);
    }

    function _singlePopulate(address _account, uint256 _dayNo, uint256 _id) internal {
        accounts[_account].pushStream(_dayNo, _id);
    }

    // call the lazy draw down function
    function lazyDrawdown(address _account) external {
        // makes sure the account exists
        require(address(accounts[_account]) != address(0));
        // gets the index of the first day var
        uint256 _firstDay = accounts[_account].firstDay();
        // gets the next item on the list
        uint256 _id = accounts[_account].pop();
        // drains the stream from the
        IpeepoPay(peepoPayCont).drainStream(_account, _id);
        // get how often its called
        // _secondsInDay = 86400
        ( , , , uint256 _freq) = IpeepoPay(peepoPayCont).gets(_account, _id);
        _freq = _freq < 86400 ? 0 : (_freq / 86400) - 1;
        // ^ this takes how often its supposed to happen converts it into days and subtracts 1 meaning
        // 0 or 1 days it does not matter it happens tomorrow
        _firstDay = _firstDay < accounts[_account].firstDay() ? accounts[_account].firstDay() : _firstDay++;
        // gets the max from the incremented day vs when it should next fall
        _firstDay += (86400 + block.timestamp - accounts[_account].sinceLast()) / 86400;
        // checks for a catch up if its a few days behind and accounts for it
        _singlePopulate(_account, _firstDay + _freq, _id);
    }

    function removeStream(uint256 _dayNo, uint256 _IDIndex) external {
        accounts[msg.sender].removeStream(_dayNo, _IDIndex);
    }

    // set up keer3r jobs
}
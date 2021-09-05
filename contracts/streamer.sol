// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IalcV2Vault} from "./interfaces/IalcV2Vault.sol";
import {Istreamer} from "./interfaces/Istreamer.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IcustomRouter} from "./interfaces/IcustomRouter.sol";

// todo: integrate w Keep3r
//done // needs testing // make sure that people can add an end date
//done // custom cont routing
                            // coin addr
                            // to addr
                            // amount
                            // address[] route
//done // needs bug fixing // emit failed draw down of streams
// view function that finds who can be drawn down
// lazy update system

contract streamer {
    // from => ID => stream
    // view function to return the IDs of all steams
    // swap into any erc-20 as well

    // how much an address gets
    // fromAdr -> toAdr -> amount
    // this creates a many to many relationship but it only allows one stream for each pair of addresses
//    mapping(address => mapping(address => stream)) public gets;
    // so its going to get replaced with an ID system
    mapping(address => mapping(uint256 => stream)) public gets;
    // this means that now a single from address can find an index list of all of their streams

    struct stream{
        address payee; // this has been added in the ID system
        uint256 cps; // coins per second
        uint256 sinceLast; // unix time since the last withdrawl was made
        uint256 freq; // how often can they withdraw so 1 once a week would be 604800
        uint256 end;
// can be set to 0 to replicate a system like sablier
//        bool openDrawDown; //allows for minimal gas to be used to close the steam
        // i chose to remove openDrawDown because tbh its not useful and seems kinda pointless
        // im adding this field because it then allows custom routes for any stream
        // if its 0 then it skips it
        // if the route is empty then it has no reason to be run as there are no custom contracts to go through
        address[] route;
    }

    // this allows the payer to know what index to search up to
    mapping(address => uint256) public streams;

    // dont think is needed in the ID based system
//    // mby needed to help keep track
//    mapping(uint256 => mapping(address => bool)) internal addressIndex;

    // dont have all the info here so its harder to test something when you cant see it
    // vault info
    address public adrAlcV2;
//    IalcV2Vault public vault;

    // address of erc-20 coin used alAsset (alUSD ot alETH...)
    address public coinAddress;

    // address of the admin
    address public admin;

    constructor () {
        admin = msg.sender;
    }

    /*
    allows the contract to point to a new alcV2 contract because of upgrades or stuff like that
    */
    function changeAlcV2 (address _new) external {
        // only admin address can call this (could be changed to the multisig or DAO)
        require(msg.sender == admin, "admin only");
        // cant set it to 0 address
        require(_new != address(0));
        // sets new address
        adrAlcV2 = _new;
//         //updates the vault cont
//        vault = IalcV2Vault(_new);
        // emits an update
        emit changedAlcV2(_new);
    }

    /*
    changes the address of the erc-20 token to something else
    */
    function setCoinAddress (address _new) external {
        // only admin can call this (could be changed to the multisig or DAO)
        require(msg.sender == admin, "admin only");
        // the 0 address isnt a contract
        require(_new != address(0));
        // sets the address of the erc-20 token
        coinAddress = _new;
        // emits a call
        emit coinAddressChanged(_new);
    }


    /*
    changes the address of the admin to something else
    */
    function changeAdmin (address _new) external {
        // only admin can call this (could be changed to the multisig or DAO)
        require(msg.sender == admin, "admin only");
        // the 0 address isnt a contract
        require(_new != address(0));
        // sets the address of the admin
        admin = _new;
        // emits a call
        emit adminChanged(_new);
    }

    /*
    this is the code that i wrote first time it doesnt use the ID system
    */
/*
    // create stream
    function createStream(
        uint256 _cps, // coins per second
        address _to, // the payee
        uint256 _freq, // uinx time
        bool _openDrawDown, // allow any address to call on your behalf in true
    // if false only certain addresses are allowed (see below)
        address[] memory _approvals // the only certain addresses
    ) external {
        // if you let anyone draw down then you cant have a list of approvals
        if(_openDrawDown){require(_approvals.length == 0);}
        // duh you should not send money to 0 address
        require(_to != address(0), "cannot stream to 0 address");
        // cant send 0 coins
        require(_cps > 0, "should not stream 0 coins");

        // gets
        // uses the mapping to set the steam up
        gets[msg.sender][_to] = stream(_cps, block.timestamp, _freq, _openDrawDown, streams); // need to work on this
        // approvals mapping filling in
        for(uint256 i=0; i < _approvals.length; i++){
            addressIndex[streams][_approvals[i]] = true;
        }
        emit streamStarted(msg.sender, _to, streams);
        // counts the number of streams
        streams += 1;
    }
*/

    /*
    new code that has the ability to do multiple streams to and from the same address
    so adr A send B 100 per hour
    and adr A send B 100 per week
    */
    function createStream(
        uint256 _cps, // coins per second
        address _to, // the payee
        uint256 _freq, // uinx time
        uint256 _start, // unix time for it to start the stream on
        uint256 _end, // 0 means no end
        bool _now,
        address[] memory _route
    // this can allow the creation of back pay or to start the stream next saturday
    ) external {
        // duh you should not send money to 0 address
        require(_to != address(0), "cannot stream to 0 address");
        // cant send 0 coins
        require(_cps > 0, "should not stream 0 coins");
        // gets the next stream ID number
        uint256 _nextID = streams[msg.sender];
        // uses the mapping to set the steam up
        _start = _now ? block.timestamp : _start;

        gets[msg.sender][_nextID] = stream(_to, _cps, _start, _freq, _end, _route); // need to work on this

        // increments the number of streams from that address (starting from a 0)
        streams[msg.sender]++;

        emit streamStarted(msg.sender, _nextID);
    }

    /*
    this is the old code before the ID bases system
    */
    // close stream
/*
    function closeStream(address _to) external {
        // cant close a stream to the 0 addr
        require(_to != address(0), "cannot stream to 0 address");

        stream memory _temp = gets[msg.sender][_to];
        // its not already closed
        require(0 < _temp.cps);
        // gets
        // sets CPS to 0
        gets[msg.sender][_to].cps = 0;
        gets[msg.sender][_to].sinceLast = block.timestamp;
        emit streamClosed(msg.sender, _to, _temp.ID);
    }
*/

    /*
    new function that uses the ID system
    */
    function closeStream(
        uint256 _id // the ID of the stream
    ) external {
        gets[msg.sender][_id].cps = 0;
        emit streamClosed(msg.sender, _id);
    }

    /*
    this is the previous thing that allowed the draw downs
    */
/*
    // draw down from stream //temp adj for testing
    function drainStreams(address _to, // address that receives
        address[] memory _arrayOfStreamers, // addresses that feed into _to
        uint256[] memory _amounts // the amount of coins they want to draw down from each address
    ) external returns (uint256 _amount) {

        // for i in the array of streams to be drawn down
        for(uint256 i=0; i < _arrayOfStreamers.length; i++){
            stream memory _temp = gets[_arrayOfStreamers[i]][_to];

            // will combine all these (keep it simple to begin w)
            if((!_temp.openDrawDown && addressIndex[_temp.ID][msg.sender]) ||
                _temp.openDrawDown){

                // makes sure that it can be drawn down and that you arnt asking for it before you get it
                if(block.timestamp >= _temp.freq + _temp.sinceLast){
                    uint256 _temp = (block.timestamp - _temp.sinceLast) * _temp.cps;

                    // takes the smaller of the 2 values (what they are asking to draw down and what they are allowed to)
                    if(_amounts[i] <= _temp && _amounts[i] > 0){
                        _temp = _amounts[i]; //defaults to the max amount it can ask for if not enough
                    }

                    _amount += _amounts[i];

                    // calls the borrow function in V2
                    (bool success, bytes memory returnData) =
                    address(adrAlcV2).call(
                        abi.encodePacked(
                            vault.mintFrom.selector,
                            abi.encode(_arrayOfStreamers[i], _temp, _to)));

                    if (success) { //cant test V2 yet
                        gets[_arrayOfStreamers[i]][_to].sinceLast = block.timestamp;
                        _arrayOfStreamers[i] = address(0);
                    }
                }
            }
        }
        emit streamDrain(_arrayOfStreamers); // returns an array of all unsuccessful drains
        return _amount; // need to test
    }
*/

    /*
    need to add some way of telling the user what streams didnt work
    */
    function drainStreams(
        address[] memory _payers, // address that receives
        uint256[] memory _IDs, // addresses that feed into _to
        uint256[] memory _amounts // the amount of coins they want to draw down from each address
    ) external {
        // gets a var for how many streams are being interacted with
        uint256 length = _payers.length;
        // makes sure all the arrays are the same side (uses the transitive law)
        require(length == _IDs.length, "_IDs array wrong length");
        require(length == _amounts.length, "_amounts array wrong length");

        // for loop to go through them all

        // IDFK
//        address[] storage failed;
//        uint256[] storage ids;
        for (uint256 i; i < length; i++){
            // trying to be gas eff here instead of calling the mapping each time use an abstracting variable
            stream memory _stream = gets[_payers[i]][_IDs[i]];
            // if the end of the stream is in the future or 0 (no end) then its okay
            uint256 _amount;
            if(_stream.end >= block.timestamp || _stream.end == 0){
                // get amount its basically a min function `min(asking for, can offer)` and making sure that its allowed to
                _amount = (_stream.freq + _stream.sinceLast) <= block.timestamp ?
                (block.timestamp - _stream.sinceLast) * _stream.cps : 0;
            } else { // else it has to allow people to draw down their remaining balance
                _amount = (_stream.freq + _stream.sinceLast) <= _stream.end ?
                (_stream.end - _stream.sinceLast) * _stream.cps : 0;
            }

            // custom cont stuff here
            bool success;
            bytes memory returnData;
            if(_stream.route.length == 0){
                // if it is not a custom contract
                // calls the borrow function in V2
                (success, returnData) = _amount > 0 ? address(adrAlcV2).call( // if they are goin to get more than 0 coins
                // then they are okay if they will get 0 coins then dont call the function
                    abi.encodePacked(
                        IalcV2Vault.mintFrom.selector,
                        abi.encode(
                            _payers[i],
                            _amount, _stream.payee
                        )
                    )
                ) : (false, bytes("0x")); // this bit here says that if your calling it to soon then you auto fail
                // if its successful then update the streams data
                if (success) { //cant test V2 yet
                    gets[_payers[i]][_IDs[i]].sinceLast += block.timestamp;
                    // needs work idk how people want this to behave
                }
            } else {
                // if it is a custom contract
                /*
                this allows for people to route funds though custom contracts
                like if you want to swap it to something or deposit into another protocol or anything
                */
                // calls the borrow function in V2
                (success, returnData) = _amount > 0 ? address(adrAlcV2).call( // if they are goin to get more than 0 coins
                // then they are okay if they will get 0 coins then dont call the function
                    abi.encodePacked(
                        IalcV2Vault.mintFrom.selector,
                        abi.encode(
                            _payers[i],
                            _amount, _stream.route[0] //send it to this contract so it can then pass it on to the customCont
                        )
                    )
                ) : (false, bytes("0x")); // this bit here says that if your calling it to soon then you auto fail
                if(success && _stream.route.length > 0){

                    (success, returnData) = _amount > 0 ? address(_stream.route[0]).call( // if they are goin to get more than 0 coins
                    // then they are okay if they will get 0 coins then dont call the function
                        abi.encodePacked(
                            IcustomRouter.route.selector,
                            abi.encode(
                                coinAddress,
                                _stream.payee,
                                _amount, //calls the custom contract to then start the process
                                _stream.route,
                                1
                            )
                        )
                    ) : (false, bytes("0x")); // this bit here says that if your calling it to soon then you auto fail
                    if(success){
                        uint256 _balance = IERC20(coinAddress).balanceOf(_stream.route[0]);

                        if(_balance == 0){
                            gets[_payers[i]][_IDs[i]].sinceLast = block.timestamp;
                        }
                    }
                }
            }
            // IDFK
//            if(!success){
//                failed.push(_payers[i]);
//                ids.push(_IDs[i]);
//            }
        }
//        emit failedDrawDowns(failed, ids);
    }

    event streamStarted (
        address from,
        uint256 indexed ID
    );

    event failedDrawDowns (
        address[] froms,
        uint256[] IDs
    );

    event streamClosed (
        address from, // not sure if this one is needed
        uint256 indexed ID
    );

    event changedAlcV2 (
        address indexed newAddr
    );

    event coinAddressChanged (
        address indexed newAddr
    );

    event adminChanged (
        address indexed newAddr
    );
}
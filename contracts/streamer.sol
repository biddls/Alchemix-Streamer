// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IalcV2Vault} from "./interfaces/IalcV2Vault.sol";
import {Istreamer} from "./interfaces/Istreamer.sol";

contract streamer {
    // creates a many to many bi-directionally lookup-able data structure
    /*
//    // from -> to
//    // not sure if its is needed but no harm in keeping it around
//    mapping(address => address[]) public fromTo;
//    // to -> from
//    mapping(address => address[]) public toFrom;
    */
    // how much an address gets
    // fromAdr -> toAdr -> amount
    mapping(address => mapping(address => stream)) public gets;

    struct stream{
        uint256 cps; // coins per second
        uint256 sinceLast; // unix time since the last withdrawl was made
        uint256 freq; // how often can they withdraw so 1 once a week would be 604800
        bool openDrawDown; //
        uint256 ID;
    }

    // get stream index so that the ID system works
    uint256 internal streams;

    // mby needed to help keep trac
    mapping(uint256 => mapping(address => bool)) internal addressIndex;

    // address of alcV2Vault
    address public adrAlcV2;

    // address of erc-20 coin used
    address public coinAddress;

    // address of the admin
    address public admin;

    constructor () {
        admin = msg.sender;
    }

    function changeAlcV2 (address _new) external {
        require(msg.sender == admin, "admin only");
        adrAlcV2 = _new;
    }

    function setCoinAddress (address _coinAddress) external {
        require(msg.sender == admin, "admin only");
        coinAddress = _coinAddress;
    }

    function changeAdmin (address _to) external {
        require(msg.sender == admin, "admin only");
        require(_to != address(0));
        admin = _to;
    }

    // create stream
    function creatStream(uint256 _cps, address _to, uint256 _freq, bool _openDrawDown, address[] memory _approvals) external {
        if(_openDrawDown){require(_approvals.length == 0);}
        require(_to != address(0), "cannot stream to 0 address");
        require(_cps > 0, "should not stream 0 coins");
        /*
        // fromAdr -> ToAdr
        fromTo[msg.sender].push(_to);
        // ToAdr -> FromAdr
        toFrom[_to].push(msg.sender);
        */
        // gets
        gets[msg.sender][_to] = stream(_cps, block.timestamp, _freq, _openDrawDown, streams); // need to work on this
        for(uint256 i=0; i < _approvals.length; i++){
            addressIndex[streams][_approvals[i]] = true;
        }
        emit streamStarted(msg.sender, _to);
        streams += 1;
    }

    // close stream
    function closeStream(address _to) external {
        require(_to != address(0), "cannot stream to 0 address");
        require(0 < gets[msg.sender][_to].cps);
        // gets
        gets[msg.sender][_to].cps = 0;
        gets[msg.sender][_to].sinceLast = block.timestamp;
        emit streamClosed(_to, block.timestamp);
    }

    // draw down from stream //temp adj for testing
    function drainStreams(address _to, address[] memory _arrayOfStreamers, uint256[] memory _amounts) external {
        uint256 _amount;
        for(uint256 i=0; i < _arrayOfStreamers.length; i++){
            stream memory _temp = gets[_arrayOfStreamers[i]][_to];
            if((!_temp.openDrawDown && addressIndex[_temp.ID][msg.sender]) ||
                _temp.openDrawDown){ // if (closed but your on the list your fine) or your open
                if(block.timestamp >= _temp.freq + _temp.sinceLast){
                    _amount = (block.timestamp - _temp.sinceLast) * _temp.cps;
                    if(_amounts[i] <= _amount && _amounts[i] > 0){
                        _amount = _amounts[i];
                    }
//                    IalcV2Vault(adrAlcV2).mintFrom(toFrom[_to][i], _amount, _to);
                    gets[_arrayOfStreamers[i]][_to].sinceLast = block.timestamp;
                }
            }
        }
    }

    function revokeApprovals(address _toAddr, address[] memory _addresses) external {
        uint256 _streamID = gets[msg.sender][_toAddr].ID;
        for(uint256 i=0; i < _addresses.length; i++){
            addressIndex[_streamID][_addresses[i]] = false;
        }
    }

    function grantApprovals(address _toAddr, address[] memory _addresses) external {
        uint256 _streamID = gets[msg.sender][_toAddr].ID;
        for(uint256 i=0; i < _addresses.length; i++){
            addressIndex[_streamID][_addresses[i]] = true;
        }
    }

    /*
    uint256 gasPerLazyLoop = 100000;
    mapping(address => uint256) lastPlace;

    // draw down from stream //temp adj for testing
    // smart loop
    function collectStreamsLazy() external {
        uint256 change;
        stream memory _temp;
        for(uint256 i=lastPlace[msg.sender]; i < toFrom[msg.sender].length; i++){
            _temp = gets[toFrom[msg.sender][i]][msg.sender];
            if(block.timestamp < _temp.freq + _temp.sinceLast){break;}
            change = block.timestamp - _temp.sinceLast;
//            IalcV2Vault(adrAlcV2).mintFrom(toFrom[msg.sender][i], change * _temp.cps, msg.sender);
            if(gasleft() < gasPerLazyLoop){
                lastPlace[msg.sender] = i;
                return;
            }
        }
        lastPlace[msg.sender] = 0;
        // emmit event to say all the addresses are checked
    }
    */

    event streamStarted (
        address indexed from,
        address indexed to
    );

    event streamClosed (
    //        address indexed from, // not sure if this one is needed
        address indexed to,
        uint256 indexed when
    );
}
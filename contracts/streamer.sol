// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IalcV2Vault} from "./interfaces/IalcV2Vault.sol";
import {Istreamer} from "./interfaces/Istreamer.sol";

contract streamer {
    // creates a many to many bi-directionally lookup-able data structure
//    // from -> to
//    // not sure if this one is needed but no harm in keeping it around
//    mapping(address => address[]) public fromTo;
    // to -> from
    mapping(address => address[]) public toFrom;
    // how much an address gets
    // fromAdr -> toAdr -> amount
    mapping(address => mapping(address => stream)) public gets;

    struct stream{
        uint256 cps; // coins per second
        uint256 sinceLast; // unix time since the last withdrawl was made
        uint256 freq; // how often can they withdraw so 1 once a week would be 604800
    }
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
    function creatStream(uint256 _cps, address _to, uint256 _freq) external {
        require(_to != address(0), "cannot stream to 0 address");
        require(_cps > 0, "should not stream 0 coins");
//        // fromAdr -> ToAdr
//        fromTo[msg.sender].push(_to);
        // ToAdr -> FromAdr
        toFrom[_to].push(msg.sender);
        // gets
        gets[msg.sender][_to] = stream(_cps, block.timestamp, _freq);
        emit streamStarted(_to, block.timestamp, _cps, _freq);
    }

    // close stream
    function closeStream(address _to) external {
        require(_to != address(0), "cannot stream to 0 address");
        // gets
        gets[msg.sender][_to] = stream(0, block.timestamp, 0);
        emit streamClosed(_to, block.timestamp);
    }

    // draw down from stream //temp adj for testing
    function collectStreams(address[] arrayOfStreamers) external {
        for(uint256 i=0; i < arrayOfStreamers.length; i++){
            stream memory _temp = gets[arrayOfStreamers[i]][msg.sender];
            if(block.timestamp < _temp.freq + _temp.sinceLast){break;}
//            IalcV2Vault(adrAlcV2).mintFrom(toFrom[msg.sender][i], (block.timestamp - _temp.sinceLast) * _temp.cps, msg.sender);
            gets[arrayOfStreamers[i]][msg.sender].sinceLast = block.timestamp;
        }
    }

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

    event streamStarted (
//        address indexed from, // not sure if this one is needed
        address indexed to,
        uint256 indexed when,
        uint256 cps,
        uint256 freq
    );

    event streamClosed (
    //        address indexed from, // not sure if this one is needed
        address indexed to,
        uint256 indexed when
    );
}
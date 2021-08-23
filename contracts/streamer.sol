// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IalcV2Vault} from "./interfaces/IalcV2Vault.sol";
import {Istreamer} from "./interfaces/Istreamer.sol";

contract streamer {
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

    // vault info
    address public adrAlcV2;
    IalcV2Vault public vault;

    // address of erc-20 coin used
    address public coinAddress;

    // address of the admin
    address public admin;

    constructor () {
        admin = msg.sender;
    }

    function changeAlcV2 (address _new) external {
        require(msg.sender == admin, "admin only");
        require(_new != address(0));
        adrAlcV2 = _new;
        vault = IalcV2Vault(_new);
        emit changedAlcV2(_new);
    }

    function setCoinAddress (address _new) external {
        require(msg.sender == admin, "admin only");
        require(_new != address(0));
        coinAddress = _new;
        emit coinAddressChanged(_new);
    }

    function changeAdmin (address _new) external {
        require(msg.sender == admin, "admin only");
        require(_new != address(0));
        admin = _new;
        emit adminChanged(_new);
    }

    // create stream
    function createStream(
        uint256 _cps, address _to, uint256 _freq, bool _openDrawDown, address[] memory _approvals
    ) external {
        if(_openDrawDown){require(_approvals.length == 0);}
        require(_to != address(0), "cannot stream to 0 address");
        require(_cps > 0, "should not stream 0 coins");

        // gets
        gets[msg.sender][_to] = stream(_cps, block.timestamp, _freq, _openDrawDown, streams); // need to work on this
        for(uint256 i=0; i < _approvals.length; i++){
            addressIndex[streams][_approvals[i]] = true;
        }
        emit streamStarted(msg.sender, _to, streams);
        streams += 1;
    }

    // close stream
    function closeStream(address _to) external {
        require(_to != address(0), "cannot stream to 0 address");
        stream memory _temp = gets[msg.sender][_to];
        require(0 < _temp.cps);
        // gets
        gets[msg.sender][_to].cps = 0;
        gets[msg.sender][_to].sinceLast = block.timestamp;
        emit streamClosed(msg.sender, _to, _temp.ID);
    }

    // draw down from stream //temp adj for testing
    function drainStreams(address _to, // address that receives
        address[] memory _arrayOfStreamers, // addresses that feed into _to
        uint256[] memory _amounts) external { // the amount of coins they want to draw down from each address

        uint256 _amount;

        for(uint256 i=0; i < _arrayOfStreamers.length; i++){
            stream memory _temp = gets[_arrayOfStreamers[i]][_to];

            // will combine all these (keep it simple to begin w)
            if((!_temp.openDrawDown && addressIndex[_temp.ID][msg.sender]) ||
                _temp.openDrawDown){

                if(block.timestamp >= _temp.freq + _temp.sinceLast){
                    _amount = (block.timestamp - _temp.sinceLast) * _temp.cps;

                    if(_amounts[i] <= _amount && _amounts[i] > 0){
                        _amount = _amounts[i]; //defaults to the max amount it can ask for if not enough
                    }

                    (bool success, bytes memory returnData) =
                    address(adrAlcV2).call(
                        abi.encodePacked(
                            vault.mintFrom.selector,
                            abi.encode(_arrayOfStreamers[i], _amount, _to)));

                    if (success) { //cant test V2 yet
                        gets[_arrayOfStreamers[i]][_to].sinceLast = block.timestamp;
                        _arrayOfStreamers[i] = address(0);
                    }
                }
            }
        }
        emit streamDrain(_arrayOfStreamers); // returns an array of all unsuccessful drains
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

    event streamStarted (
        address from,
        address to,
        uint256 indexed ID
    );

    event streamClosed (
        address from, // not sure if this one is needed
        address to,
        uint256 indexed ID
    );

    event streamDrain (
        address[] failed // 0 addresses are to be ignored
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
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IalcV2Vault} from "./interfaces/IalcV2Vault.sol";
import {Istreamer} from "./interfaces/Istreamer.sol";

contract streamer {
    // creates a many to many bi-directionally lookup-able data structure
    // from -> to
    mapping(address => address[]) public fromTo;
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
        // fromAdr -> ToAdr
        fromTo[msg.sender].push(_to);
        // ToAdr -> FromAdr
        toFrom[_to].push(msg.sender);
        // gets
        gets[msg.sender][_to] = stream(_cps, block.timestamp, _freq);
    }

    // close stream
    function closeStream(address _to) external {
        require(_to != address(0), "cannot stream to 0 address");
        // gets
        gets[msg.sender][_to] = stream(0, block.timestamp, 0);
    }

    // draw down from stream
    function drawDown() external {
        uint256 total;
        uint256 change;
        stream memory _temp;
        for(uint256 i=0; i < toFrom[msg.sender].length; i++){
            _temp = gets[toFrom[msg.sender][i]][msg.sender];
            if(block.timestamp < _temp.freq + _temp.sinceLast){break;}
            change = block.timestamp - _temp.sinceLast;
            total += change * _temp.cps;
        }
        IalcV2Vault(adrAlcV2).mint(total, msg.sender);
    }
}
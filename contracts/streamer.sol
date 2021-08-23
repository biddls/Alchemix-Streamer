pragma solidity ^0.8.0;

import {IalcV2Vault} from "./interfaces/IalcV2Vault.sol";
import {Istreamer} from "./interfaces/Istreamer.sol";

contract streamer {
    // how much an address gets
    // fromAdr -> toAdr -> amount
    mapping(address => mapping(address => stream)) public gets;

    IalcV2Vault public vault;

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

    function changeAlcV2 (address _new, address _vaultAddr) external {
        require(msg.sender == admin, "admin only");
        adrAlcV2 = _new;
        vault = IalcV2Vault(_vaultAddr);
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
    function creatStream(
        uint256 _cps, address _to, uint256 _freq, bool _openDrawDown, address[] memory _approvals
    ) external {
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
    function drainStreams(address _to,
        address[] memory _arrayOfStreamers,
        uint256[] memory _amounts) external {

        uint256 _amount;

        for(uint256 i=0; i < _arrayOfStreamers.length; i++){
            stream memory _temp = gets[_arrayOfStreamers[i]][_to];

            // will combine all these (keep it simple to begin w)
            if((!_temp.openDrawDown && addressIndex[_temp.ID][msg.sender]) ||
                _temp.openDrawDown){

                if(block.timestamp >= _temp.freq + _temp.sinceLast){
                    _amount = (block.timestamp - _temp.sinceLast) * _temp.cps;

                    if(_amounts[i] <= _amount && _amounts[i] > 0){
                        _amount = _amounts[i];
                    }

//                    (bool success, bytes memory returnData) =
//                    address(token).call(
//                        abi.encodePacked(
//                            vault.mintFrom.selector,
//                            abi.encode(toFrom[_to][i], _amount, _to)));

//                    if (success) {
                    gets[_arrayOfStreamers[i]][_to].sinceLast = block.timestamp;
                    emit streamDrain(_to, _amount);
//                    }
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
        address to,
        uint256 ammount
    );
}
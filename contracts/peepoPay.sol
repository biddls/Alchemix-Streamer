// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IalcV2Vault} from "./interfaces/IalcV2Vault.sol";
import {IpeepoPay} from "./interfaces/IpeepoPay.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IcustomRouter} from "./interfaces/IcustomRouter.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title PeepoPay
/// @author Biddls.eth
/// @notice Allows users to set up streams with custom contract routing
/// @dev the lower feature version that requires more upkeep
contract PeepoPay is AccessControl{

    /// @dev mapping from => ID => stream
    mapping(address => mapping(uint256 => Stream)) public gets;

    /// @dev Struct that holds all the data about a stream
    struct Stream {
        /// @dev the address of the receiver
        address payee;
        /// @dev coins per second (in a granularity of 1/10^18 alUSD increments)
        uint256 cps;
        /// @dev the unix time of last withdrawal
        uint256 sinceLast;
        /// @dev how often can they withdraw so 1 once a week would be 604800 (can be set to 0 to act more like a sabiler stream)
        uint256 freq;
        /// @dev unix time marking the end of the stream (can be set to 0 to never end)
        uint256 end;
        /// reentrancy security issues
        /// @dev allows for a "route" of contracts to be immutably defined if no route is given it skips this step
        address[] route;
        /// @dev a role is generated which allows the owner to permission addresses to call collect the stream function
        bytes32 ROLE;
    }

    /// @dev keeps track of the number of streams that an account has made (closing streams does not decrement this number)
    /// this allows the payer to know what index to search up to
    mapping(address => uint256) public streams;

    /// dont have all the info here so its harder to test something when you cant see it
    /// @dev alchemix vault V2 address
    address public adrAlcV2;
    /// IalcV2Vault public vault;

    /// @dev address of erc-20 coin used alAsset (alUSD, alETH...)
    address public coinAddress;

    /// @dev Sets up a basic admin role for upgrade-ability
    constructor () {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Admin only function to change the stored address of alc V2
    /// @dev Admin only cannot pass in 0 address
    /// @param _new The new address of alcV2
    function changeAlcV2 (address _new) external {
        // only admin address can call this (could be changed to the multisig or DAO)
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        // cant set it to 0 address
        require(_new != address(0));
        // sets new address
        adrAlcV2 = _new;
//         //updates the vault cont
//        vault = IalcV2Vault(_new);
        // emits an update
        emit changedAlcV2(_new);
    }

    /// @notice Changes the address of the erc-20 token it gets from the vault
    /// @dev Admin only cannot pass in 0 address
    /// @param _new The new address of the alAsset coin
    function setCoinAddress (address _new) external {
        // only admin can call this (could be changed to the multisig or DAO)
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        // the 0 address isnt a contract
        require(_new != address(0));
        // sets the address of the erc-20 token
        coinAddress = _new;
        // emits a call
        emit coinAddressChanged(_new);
    }

    /// @notice Changes the address of the admin
    /// @dev Admin only cannot pass in 0 address
    /// @param _new The new address of admin
    function changeAdmin (address _new) external {
        // only admin can call this (could be changed to the multisig or DAO)
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        // the 0 address isnt a contract
        require(_new != address(0));
        // sets the address of the admin
        grantRole(DEFAULT_ADMIN_ROLE, _new);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // emits a call
        emit adminChanged(_new);
    }

    /// @notice Allows the user to create a stream
    /// @dev This works from msg.sender so you cant do this on behalf of another address with out building something externaly
    /// @param _to the address of the receiver
    /// @param _cps coins per second (in a granularity of 1/10^18 alUSD increments)
    /// @param _freq the unix time of last withdrawal
    /// @param _start how often can they withdraw so 1 once a week would be 604800 (can be set to 0 to act more like a sabiler stream)
    /// @param _end unix time marking the end of the stream (can be set to 0 to never end)
    /// @param _route allows for a "route" of contracts to be immutably defined if no route is given it skips this step
    function createStream(
        address _to, // the payee
        uint256 _cps, // coins per second
        uint256 _freq, // uinx time
        uint256 _start, // unix time for it to start the stream on
    /// this ^ can allow the creation of back pay or to start the stream next saturday
        uint256 _end, // 0 means no end
        address[] memory _route
    ) external {
        /// duh you should not send money to 0 address
        require(_to != address(0), "cannot stream to 0 address");
        /// cant send 0 coins
        require(_cps > 0, "should not stream 0 coins");
        /// gets the next stream ID number
        uint256 _nextID = streams[msg.sender];
        gets[msg.sender][_nextID] = Stream(_to, _cps, _start, _freq, _end, _route, "");
        gets[msg.sender][_nextID].ROLE = genRole(msg.sender, _nextID, gets[msg.sender][_nextID]);
        grantRole(gets[msg.sender][_nextID].ROLE, msg.sender);
        /// increments the number of streams from that address (starting from a 0)
        streams[msg.sender]++;

        emit streamStarted(msg.sender, _nextID, _to);
    }

    /// @notice Allows the user to edit a stream
    /// @dev This works from msg.sender so you cant do this on behalf of another address with out building something externaly
    /// @param _id the ID of the stream
    /// @param _emergencyClose A bool that either allows for back pay or does not
    /// @param _end if back pay is allowed, until when?
    /// ## NOT TESTED YET ##
    function editStream(
        uint256 _id, // the ID of the stream
        bool _emergencyClose,
        uint256 _end
    ) external {
        if(!_emergencyClose){
            gets[msg.sender][_id].end = _end;
            // empties the stream and then deletes it if its already closed
            if(_end < block.timestamp){
                _collectStream(msg.sender, _id);
                delete gets[msg.sender][_id];
                emit streamClosed(msg.sender, _id);
            }
        } else {
            // deletes it without the opportunity for the receiver to claim what ever they owe
            delete gets[msg.sender][_id];
            emit streamClosed(msg.sender, _id);
        }
    }

    // todo: add priority ordering AKA: "fucking kill me this is going to suck"
    // unclaimed funds that are owed to each person are earmarked for
    // the ID but a higher priority can dip into the buckets of lower IDs
    // todo: allow priorities to be changed

    function collectStream(
        address _payer, // address that gives
        uint256 _ID // is of the stream
    ) external returns (bool success){
        Stream memory _stream = gets[_payer][_ID];
        require(hasRole(genRole(_payer, _ID, _stream), msg.sender), "addr dont have access");
        success = _collectStream(_payer, _ID);
    }

    // not tested
    function _collectStream(
        address _payer, // address that gives
        uint256 _ID // is of the stream
    ) internal returns (bool success){
        Stream memory _stream = gets[_payer][_ID];
        uint256 _amount = streamSize(_payer, _ID);

        // if it is not a custom contract
        // calls the borrow function in V2
        IalcV2Vault(adrAlcV2).mintFrom(
            _payer,
            _amount,
        // this either sends the funds to the 1st custom cont or payee depending on if there is a route or not
            _stream.route.length > 0 ? _stream.route[0] : _stream.payee
        );

        gets[_payer][_ID].sinceLast += block.timestamp;

        if(_stream.route.length > 0){
            /*
            // if it is a custom contract
            this allows for people to route funds though custom contracts
            like if you want to swap it to something or deposit into another protocol or anything
            // no risk of reentrancy as nothing else in the contract after this relies on the contracts own internal data
            */
            //##############################
            //###RISK OF REENTERANCY HERE###
            //##############################
            IcustomRouter(_stream.route[0]).route(
                coinAddress,
                _stream.payee,
                _amount,
                _stream.route,
                1);

            require(0 == IERC20(coinAddress).balanceOf(_stream.route[0]), "Coins did not move on");
        }
        return success;
    }

    // view function to tell it how much it will receive for a given address and ID of stream
    function streamSize(
        address _payer, // address that gives
        uint256 _ID // is of the stream
    ) view public returns (uint256 _amount){
        Stream memory _stream = gets[_payer][_ID];
        if((_stream.end >= block.timestamp) || (_stream.end == 0)){
            _amount = (_stream.freq + _stream.sinceLast) <= block.timestamp ?
            (block.timestamp - _stream.sinceLast) * _stream.cps : 0;
        } else {
            _amount = (_stream.freq + _stream.sinceLast) <= _stream.end ?
            (_stream.end - _stream.sinceLast) * _stream.cps : 0;
        }
    }

    function genRole(
        address _from,
        uint256 _ID,
        Stream memory _stream
    ) pure public returns (bytes32 _ROLE){
        return keccak256(abi.encodePacked(_from, _ID, _stream.payee, _stream.cps, _stream.freq, _stream.end));
    }

    function streamPermGrant(uint256 _ID, address _account) external {
        grantRole(streamRoleChngChecks(_ID, _account), _account);
    }
    function streamPermRevoke(uint256 _ID, address _account) external {
        revokeRole(streamRoleChngChecks(_ID, _account), _account);
    }
    function streamRoleChngChecks(uint256 _ID, address _account) view internal returns (bytes32){
        require(msg.sender != _account, "no access allowed");
        return genRole(msg.sender, _ID, gets[msg.sender][_ID]);
    }

    event streamStarted (
        address indexed from,
        uint256 indexed ID,
        address indexed to
    );

    event streamClosed (
        address indexed from, /// not sure if this one is needed
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

    /// think about what events im going to emit
}
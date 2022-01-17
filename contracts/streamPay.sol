// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IalcV2Vault} from "./interfaces/IalcV2Vault.sol";
import {IStreamPay} from "./interfaces/IStreamPay.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IcustomRouter} from "./interfaces/IcustomRouter.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SimpleSummedArrays} from "./SummedArrays/SimpleSummedArrays.sol";

/// @title StreamPay
/// @author Biddls.eth
/// @notice Allows users to set up streams with custom contract routing
/// @dev the lower feature version that requires more upkeep
contract StreamPay is AccessControl{

    /// @dev mapping from => ID => stream
    mapping(address => mapping(uint256 => Stream)) public gets;

    // todo: merge both of these in just a general "account info thing"
    /// @dev mapping from => Reserved stream
    mapping(address => ResStream) public reserved;
    /// @dev mapping account => total CPS for each payer
    mapping(address => uint256) public totalCPS;

    /// @dev maximum search distance
    uint8 public maxIndex;

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
        /// @dev denotes if this stream is a reserved stream or not
        uint16 reserveIndex;
    }

    /// @dev Struct that holds all the data about a reserved stream
    struct ResStream {
        /// @dev total above it summed: cps
        SimpleSummedArrays reservedList;
        /// @dev tells the contract if the mapping is empty
        bool alive;
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
    constructor (uint8 _maxIndex) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        maxIndex = _maxIndex;
    }

    /// @notice Admin only function to change the stored address of alc V2
    /// @dev Admin only cannot pass in 0 address
    /// @param _new The new address of alcV2
    function changeAlcV2(address _new) external adminOnly {
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
    function setCoinAddress(address _new) external adminOnly {
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
    function changeAdmin(address _new) external adminOnly {
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
        /// cant end before _start
        require(_end == 0 || _end > _start, "Cant end before you have started, unless it never ends");
        /// gets the next stream ID number
        uint256 _nextID = streams[msg.sender];
        // fills in the database about the stream
        gets[msg.sender][_nextID] = Stream(_to, _cps, _start, _freq, _end, _route, "", maxIndex);
        // updates counter for total CPS payout
        totalCPS[msg.sender] += _cps;
        // sets the role string that represents the role
        gets[msg.sender][_nextID].ROLE = genRole(msg.sender, _nextID, gets[msg.sender][_nextID]);
        // sets the correct permissions for the stream
        grantRole(gets[msg.sender][_nextID].ROLE, msg.sender);
        /// increments the number of streams from that address (starting from a 0)
        streams[msg.sender]++;
        require(streams[msg.sender] > 0);
        // emmit events
        emit streamStarted(msg.sender, _nextID, _to);
    }

    /// @notice Allows the user to edit a streams end date
    /// @dev This works from msg.sender so you cant do this on behalf of another address with out building something externaly
    /// @param _id the ID of the stream
    /// @param _emergencyClose A bool that either allows for back pay or does not
    /// @param _end if back pay is allowed, until when?
    function editStream(
        uint256 _id, // the ID of the stream
        bool _emergencyClose,
        uint256 _end
    ) public {
        if(_emergencyClose && _end < block.timestamp){
            _collectStream(msg.sender, _id, gets[msg.sender][_id]);
        }
        _editStream(_id, _emergencyClose, _end);
    }

    function _editStream(
        uint256 _id, // the ID of the stream
        bool _emergencyClose,
        uint256 _end
    ) internal {
        if(_emergencyClose){
            if(_end < block.timestamp && reserved[msg.sender].alive){
                reserved[msg.sender].reservedList.clear(gets[msg.sender][_id].reserveIndex);
            }
            // updates total payout rate
            totalCPS[msg.sender] -= gets[msg.sender][_id].cps;
            // deletes it without the opportunity for the receiver to claim what ever they owe
            delete gets[msg.sender][_id];
            emit streamClosed(msg.sender, _id);
            return;
        }
        gets[msg.sender][_id].end = _end;
        // updates the res stream data
        if(_end < block.timestamp){
            if(reserved[msg.sender].alive){
                reserved[msg.sender].reservedList.clear(gets[msg.sender][_id].reserveIndex);
            }
            emit streamClosed(msg.sender, _id);
        }
    }

    /// @notice Allows the user to edit a streams CPS
    /// @dev This works from msg.sender so you cant do this on behalf of another address with out building something externaly
    /// @param _id the ID of the stream
    /// @param _cps new cps
    function editStreamCps(
        uint256 _id, // the ID of the stream
        uint256 _cps
    ) external {
        // close the stream if CPS is 0
        if(_cps == 0){editStream(_id, true, 0);return;}
        // holds old data
        uint256 _oldCps = gets[msg.sender][_id].cps;
        // makes sure that there is a change happening
        require(_oldCps != _cps);
        // updates totalCPS (payout rate)
        _oldCps > _cps ? totalCPS[msg.sender] -= _oldCps - _cps : totalCPS[msg.sender] += _oldCps - _cps ;
        // updates on chain data
        gets[msg.sender][_id].cps = _cps;
        // empties the stream and then deletes it if its already closed
        if(reserved[msg.sender].alive){
            reserved[msg.sender].reservedList.clear(gets[msg.sender][_id].reserveIndex);
        }
    }

    function clearReservedStream (
        address _account,
        uint16 _index
    ) internal {
        require(reserved[_account].alive, "Account not setup for reservations");
        reserved[_account].reservedList.clear(_index);
    }

    /// @notice Allows an approved address to collect a stream
    /// @param _payer the address that gives
    /// @param _id the ID of the stream
    function collectStream(
        address _payer,
        uint256 _id
    ) external returns (bool success){
        Stream memory _stream = gets[_payer][_id];
        require(hasRole(genRole(_payer, _id, _stream), msg.sender), "addr dont have access");
        success = _collectStream(_payer, _id, _stream);
    }

    /// @dev internal function
    /// @param _payer the address that gives
    /// @param _id of the stream
    function _collectStream(
        address _payer,
        uint256 _id,
        Stream memory _stream
    ) internal returns (bool success){
        // returns how much its asking for
        uint256 _amount;
        // reserved streams management
        // sets how much can be drawn down
        if(reserved[_payer].alive) {
            _amount = calcEarMarked(_payer, _stream.reserveIndex, 0, false);
        } else {
            _amount = streamSize(_payer, _id);
            // updates values held in the SummedArrays
        }
        // if it is not a custom contract
        // calls the borrow function in V2
        IalcV2Vault(adrAlcV2).mintFrom( // <- TODO integration with V2
            _payer,
            _amount,
        // this either sends the funds to the 1st custom cont or payee depending on if there is a route or not
            _stream.route.length > 0 ? _stream.route[0] : _stream.payee
        );

        gets[_payer][_id].sinceLast += block.timestamp;

        if(_stream.end <= block.timestamp){
            // deletes stream if its to be closed
            _editStream(_id, true, 0);{
                reserved[_payer].alive = false;
            }
        }

        if(_stream.route.length > 0){
            /*
            if it is a custom contract
            this allows for people to route funds though custom contracts
            like if you want to swap it to something or deposit into another protocol or anything
            mby no risk of reentrancy as nothing else in the
            contract after this relies on the contracts own internal state
            ##############################
            ###RISK OF REENTRANCY HERE###
            ##############################
            */
            IcustomRouter(_stream.route[0]).route(
                coinAddress,
                _stream.payee,
                _amount,
                _stream.route,
                1);

            require(0 == IERC20(coinAddress).balanceOf(_stream.route[0]), "Coins did not move on");
        }
        emit streamCollected(_payer, _amount, calcTotalPayOut(msg.sender, _id));
        return success;
    }

    /// @notice view function to tell it how much it will receive for a given address and ID of stream
    /// @dev only used for UI information
    /// @param _payer the address that gives
    /// @param _id of the stream
    function streamSize(
        address _payer,
        uint256 _id
    ) view public returns (uint256 _amount){
        Stream memory _stream = gets[_payer][_id];
        // if the stream has not closed or never closes
        if((_stream.end >= block.timestamp) || (_stream.end == 0)){
            _amount = (_stream.freq + _stream.sinceLast) <= block.timestamp ?
            (block.timestamp - _stream.sinceLast) * _stream.cps : 0;
        } else {
            // if the stream is past its close by date
            _amount = (_stream.freq + _stream.sinceLast) <= _stream.end ?
            (_stream.end - _stream.sinceLast) * _stream.cps : 0;
        }
        return _amount;
    }

    /// @notice allows the user to grant other addresses to call on his/her behalf by default the receiver and the payer have the roles
    /// @dev its done off of msg.sender so only the address paying out can change permissions
    /// @param _account it is granting
    /// @param _id the ID of the stream
    function streamPermGrant(
        address _account,
        uint256 _id
    ) external {
        grantRole(streamRoleChngChecks(_id, _account), _account);
    }

    /// @notice allows the user to grant other addresses to call on his/her behalf by default the receiver and the payer have the roles
    /// @dev its done off of msg.sender so only the address paying out can change permissions
    /// @param _account it is granting
    /// @param _id the ID of the stream
    function streamPermRevoke(
        address _account,
        uint256 _id
    ) external {
        revokeRole(streamRoleChngChecks(_id, _account), _account);
    }

    /// @notice makes the relevant checks before generating the role
    /// @param _from it is granting
    /// @param _id the ID of the stream
    function streamRoleChngChecks(
        uint256 _id,
        address _from
    ) view internal returns (bytes32){
        require(msg.sender != _from, "Stream owner must always have access");
        return genRole(msg.sender, _id, gets[msg.sender][_id]);
    }

    /// @notice generates the role required for the account and subsequent stream
    /// @param _from it is granting
    /// @param _id the ID of the stream
    function genRole(
        address _from,
        uint256 _id,
        Stream memory _stream
    ) pure internal returns (bytes32 _ROLE){
        return keccak256(abi.encodePacked(_from, _id, _stream.payee, _stream.cps, _stream.freq, _stream.end));
    }

    /// @notice allows the user to reserve a stream
    /// @param _id the ID number of the stream
    /// @param _priority where on the reserved list does it sit
    /// @dev it goes off of msg.sender so only the streams from / payee address can control this
    function reserveStream(
        uint256 _id,
        uint16 _priority
    ) external{
        require(reserved[msg.sender].alive, "Account not setup for reservations");
        // make sure the stream is alive
        require(gets[msg.sender][_id].cps != 0);
        // clear data currently held
        reserved[msg.sender].reservedList.clear(_priority);
        // writes over the same data location that was just cleared
        reserved[msg.sender].reservedList.write(
            _priority,
            gets[msg.sender][_id].cps,
            0,
            gets[msg.sender][_id].sinceLast);
        // updates local storage
//        resRevGets[msg.sender][_priority] = _id;
    }

    /// @notice gets how much is already reserved and says if an amount is possible or not
    function calcEarMarked(
        address _payer,
        uint16 _index, /*how many streams*/
        uint256 _asking,
        bool _max
    ) public returns (uint256 _canBorrow){
        // gets the amount of coins that have been reserved
        if(reserved[_payer].alive){
            _canBorrow = reserved[_payer].reservedList.calcReserved(_index, false);
        }
        // local sotrage of variable to rediuce gas
        uint256 _allowance = IalcV2Vault(adrAlcV2).allowance(_payer);
        // avoids underflow
        _canBorrow = _allowance >= _canBorrow ? _allowance - _canBorrow : 0;
    }

    /// @notice swaps the index of 2 reserved streams to change priority
    /// @param _id1 the id of the 1st stream
    /// @param _id2 the id of the 2nd stream
    function swapResStreams(
        uint256 _id1,
        uint256 _id2
    ) external {
        require(reserved[msg.sender].alive);
        // ensures proper ordering of data
        require(gets[msg.sender][_id1].reserveIndex > maxIndex);
        require(gets[msg.sender][_id2].reserveIndex > maxIndex);
        // performs the swap
        reserved[msg.sender].reservedList.swap(
            gets[msg.sender][_id1].reserveIndex,
            gets[msg.sender][_id2].reserveIndex);
    }

    function setMaxIndex(
        uint8 _max
    ) external adminOnly {
        maxIndex = _max;
    }

    /// @notice returns the total payout for the stream
    /// @dev returns max int (2**256-1) if it has no end
    /// @param _payer the address that is paying out the funds
    /// @param _id the id number of the stream
    function calcTotalPayOut(
        uint256 _payer,
        uint256 _id
    ) public view returns(uint256) {
        return gets[_payer][_id].end == 0 ? 2**256-1 :
        ((gets[_payer][_id].end - gets[_payer][_id].sinceLast) * gets[_payer][_id].cps);
    }

    /// @notice returns the max amount of coins that can be borrowed - reserved coins etc
    /// @dev take this number and / by av daily returns
    /// @param _payer the address that is paying out the funds
    function calcRunwayLeft(
        address _payer
    ) external returns (uint256 _available, uint256 _totalCps){
        _available = calcEarMarked(
            _payer,
            maxIndex,
            0,
            true);
        _totalCps = totalCPS[_payer];
    }

    modifier adminOnly {
        // only admin address can call this (could be changed to the multisig or DAO)
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        _;
    }

    /// makes account if there isn't one
    function startReservation(
        address _account) external {
        // makes sure to not duplicate the contract
        require(!reserved[_account].alive);
        // sets the admin addresses
        address[2] memory tmp = [_account, address(this)];
        // creates the contract and updates the on chain data to point to it
        reserved[_account] = ResStream(
            new SimpleSummedArrays(maxIndex, tmp),
            true);
    }

    event streamStarted (
        address indexed from,
        uint256 indexed ID,
        address indexed to
    );

    event streamClosed (
        address indexed from,
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

    event streamCollected(
        address payer,
        uint256 amount,
        uint256 runwayLeft
    );
}
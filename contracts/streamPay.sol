// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IalcV2Vault} from "./interfaces/IalcV2Vault.sol";
import {IStreamPay} from "./interfaces/IStreamPay.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IcustomRouter} from "./interfaces/IcustomRouter.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SimpleSummedArrays} from "./SummedArrays/SimpleSummedArrays.sol";
//import "hardhat/console.sol";

//todo: take out routing system
//todo: make sure events are working for everything
//todo: look into errors instead of reverts
//todo: remove comments between variables
//todo: remove freq stuff
//todo: new streams go to new ID and old one points to it
//todo: receiver can add people to admin of stream
//todo: receiver can add remove them self
//todo: add view functions to make looking up easy

/// @title StreamPay
/// @author Biddls.eth
/// @notice Allows users to set up streams with custom contract routing
/// @dev the lower feature version that requires more upkeep
/// @dev this contract holds no funds
contract StreamPay is AccessControl{

    /// @dev mapping from => ID => stream
    mapping(address => mapping(uint256 => Stream)) public gets;

    /// @dev mapping address => account data
    mapping(address => Account) public accountData;

    /// @dev holds the data for each alAsset that can be used with with contract
    mapping(uint8 => Coin) public coinData;

    /// @dev route admin role
    bytes32 public constant ROUTE_ADMIN = "RouterDaddy";

    /// @dev holds admin permitted routing options for users
    mapping(uint256 => address[]) public routes;

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
        /// @dev unix time marking the end of the stream (can be set to 0 to never end)
        uint256 end;
        /// @dev a role is generated which allows the owner to permission addresses to call collect the stream function
        bytes32 ROLE;
        /// @dev allows for a "route" of contracts to be immutably defined if no route is given it skips this step
        uint8 routeIndex;
        /// @dev denotes if this stream is a reserved stream or not
        uint8 reserveIndex;
        /// @dev denotes the index of the coin this stream handles
        uint8 coinIndex;
    }

    /// @dev Struct that holds all the data about a reserved stream
    struct Account {
        /// @dev tells the contract if the mapping is empty
        bool alive;
        /// @dev current payout rate
        mapping(uint8 => uint256) totalCPS;
        /// @dev number of streams that have ever been started
        uint256 streams;
        /// @dev reservation system ordering
        mapping(uint8 => mapping(uint8 => uint256)) reservationData;
    }

    // holds the address of a coin and the corresponding alc V2 vault
    struct Coin{
        IalcV2Vault alcV2vault;
        IERC20 alAsset;
        bool valid;
    }

    /// @dev Sets up a basic admin role for upgrade-ability
    constructor (uint8 _maxIndex) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        maxIndex = _maxIndex;
    }

    /// @notice Allows the user to create a stream
    /// @dev This works from msg.sender so you cant do this on behalf of another address with out building something externaly
    /// @param _to the address of the receiver
    /// @param _cps coins per second (in a granularity of 1/10^18 alUSD increments)
    /// @param _start how often can they withdraw so 1 once a week would be 604800 (can be set to 0 to act more like a sabiler stream)
    /// @param _end unix time marking the end of the stream (can be set to 0 to never end)
    /// @param _routeIndex allows for a "route" of contracts to be immutably defined if no route is given it skips this step
    /// @param _coinIndex allows for the user to select what coin they are streaming
    function createStream(
        address _to, // the payee
        uint256 _cps, // coins per second
        uint256 _start, // unix time for it to start the stream on
    /// this ^ can allow the creation of back pay or to start the stream next saturday
        uint256 _end, // 0 means no end
        uint8 _routeIndex,
        uint8 _coinIndex
    ) external {
        /// duh you should not send money to 0 address
        require(_to != address(0), "cannot stream to 0 address");
        /// cant send 0 coins
        require(_cps > 0, "should not stream 0 coins");
        /// cant end before _start
        require(_end == 0 || _end > _start, "Cant end before you have started, unless it never ends");
        // makes sure that it is something an admin has submitted
        require(coinData[_coinIndex].valid);
        /// gets the next stream ID number
        uint256 _streamID = accountData[msg.sender].streams;
        // fills in the database about the stream
        gets[msg.sender][_streamID] = Stream(
            _to, // payee
            _cps, // cps
            _start, // sinceLast
            _end, // end
            "", // ROLE
            _routeIndex, // routeIndex
            maxIndex, // reserveIndex
            _coinIndex // coinIndex
        );
        // updates counter for total CPS payout
        accountData[msg.sender].totalCPS[_coinIndex] += _cps;
        // sets the role string that represents the role
        gets[msg.sender][_streamID].ROLE = genRole(
            msg.sender,
            _streamID,
            gets[msg.sender][_streamID]);
        // sets the correct permissions for the stream
        grantRole(
            gets[msg.sender][_streamID].ROLE,
            msg.sender);
        /// increments the number of streams from that address (starting from a 0)
        accountData[msg.sender].streams++;
        // emmit events
        emit STREAM_STARTED(msg.sender, _streamID, _to);
    }

    /// @notice Allows the user to edit a streams end date
    /// @dev This works from msg.sender so you cant do this on behalf of another address with out building something externally
    /// @param _id the ID of the stream
    /// @param _emergencyClose A bool that either allows for back pay or does not
    /// @param _end if back pay is allowed, until when?
    function closeStream(
        uint256 _id, // the ID of the stream
        bool _emergencyClose, // close the stream and do not allow collection from the stream
        uint256 _end // new end data
    ) external {
        _closeStream(_id, _emergencyClose, _end, msg.sender);
    }

    /// @notice Internal version of edit stream that can skip the drawing down of funds (avoids infinite loop)
    /// @dev This works from msg.sender so you cant do this on behalf of another address with out building something externally
    /// @param _id the ID of the stream
    /// @param _emergencyClose A bool that either allows for back pay or does not
    /// @param _end if back pay is allowed, until when?
    function _closeStream(
        uint256 _id, // the ID of the stream
        bool _emergencyClose, // close the stream and do not allow collection from the stream
        uint256 _end, // new end data
        address _account // allows internal overriding of the msg.sender var
    ) internal {
        Stream memory _stream = gets[_account][_id];
        // deletes it without the opportunity for the receiver to claim what ever they owe
        if(_emergencyClose){
            delete accountData[msg.sender].reservationData[_stream.reserveIndex][_stream.coinIndex];
            // updates total payout rate
            accountData[_account].totalCPS[_stream.coinIndex] -= _stream.cps;
            delete gets[_account][_id];
            emit STREAM_CLOSED(_account, _id);
            return;
        } else if(_stream.end == 0){
            // if there was no close date not there is
            gets[_account][_id].end = _end;
            return;
        } else if (_end <= _stream.end){
            // if there was a close date it enforces that its closer to present
            gets[_account][_id].end = _end;
            emit STREAM_CLOSED(_account, _id);
        }
    }

    /// @notice Allows an approved address to collect a stream
    /// @param _payer the address that gives
    /// @param _id the ID of the stream
    function collectStream(
        address _payer,
        uint256 _id
    ) external {
        // stores local version of data to save gas
        Stream memory _stream = gets[_payer][_id];
        // ensuring that the address calling has the right to do so
        require(hasRole(genRole(_payer, _id, _stream), msg.sender), "addr dont have access");
        // calls the internal unchecked version of collectStream
        _collectStream(_payer, _id, _stream, false);
    }

    /// @dev internal function
    /// @param _payer the address that gives
    /// @param _id of the stream
    function _collectStream(
        address _payer,
        uint256 _id,
        Stream memory _stream,
        bool recursion
    ) internal {
        // loads the data out of storage and into memory
        Coin memory coin = coinData[_stream.coinIndex];
        // returns how much its asking for
        uint256 _amount;
        // reserved streams management
        // sets how much can be drawn down
        // todo: fix and update this
        if(accountData[_payer].alive) {
            _amount = calcEarMarked(_payer, _stream.reserveIndex, 0, false, coin.alcV2vault);
        } else {
            _amount = streamSize(_payer, _id);
        }
        // if it is not a custom contract
        // calls the borrow function in V2
        IalcV2Vault(coin.alcV2vault).mintFrom( // <- TODO integration with V2
            _payer,
            _amount,
        // this either sends the funds to the 1st custom cont or payee depending on if there is a route or not
            routes[_stream.routeIndex].length > 0 ? routes[_stream.routeIndex][0] : _stream.payee
        );

        // if the stream has ended delete it
        if(!recursion && (_stream.end <= block.timestamp)){
            // deletes stream if its to be closed
            _closeStream(_id, true, 0, _payer);
        } else {
            // updates on chain data
            gets[_payer][_id].sinceLast = block.timestamp;
        }

        if(routes[_stream.routeIndex].length > 0){
            /*
            if it is a custom contract
            this allows for people to route funds though custom contracts
            like if you want to swap it to something or deposit into another protocol or anything
            #############################
            ###RISK OF REENTRANCY HERE###
            #############################
            mby no risk of reentrancy as nothing else in the
            contract after this relies on the contracts own internal state
            */
            // todo: need to re-write docs on this and example code
            IcustomRouter(routes[_stream.routeIndex][0]).route(
                coin.alAsset, // alusd
                _stream.payee, // end reciver
                _amount, // amount of alUSd its passing on
            // todo: mby change this to the index but am not sure
                routes[_stream.routeIndex], // the list of contrants the funds move through
                1 // next index to look at
            );

            // ensures that the funds have moved on
            require(0 == IERC20(coin.alAsset).balanceOf(routes[_stream.routeIndex][0]), "Coins did not move on");
        }
        emit STREAM_COLLECTED(_payer, _amount);
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
            _amount = _stream.sinceLast <= block.timestamp ?
            (block.timestamp - _stream.sinceLast) * _stream.cps : 0;
        } else {
            // if the stream is past its close by date
            _amount = _stream.sinceLast <= _stream.end ?
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
        return keccak256(abi.encodePacked(_from, _id, _stream.payee, _stream.cps, _stream.end));
    }

    /// @notice allows the user to reserve a stream
    /// @param _id the ID number of the stream
    /// @param _priority where on the reserved list does it sit
    /// @dev it goes off of msg.sender so only the streams from / payee address can control this
    function reserveStream(
        uint256 _id,
        uint8 _priority
    ) external{
        require(accountData[msg.sender].alive, "Account not currently doing reservations");
        // make sure the stream is alive
        require(gets[msg.sender][_id].cps != 0);
        // clear data currently held
        accountData[msg.sender].reservationData[_priority][gets[msg.sender][_id].coinIndex] = _id;
    }

    /// @notice allows the user to un-reserve a stream
    /// @param _id the ID number of the stream
    /// @param _priority where on the reserved list does it sit
    /// @dev it goes off of msg.sender so only the streams from / payee address can control this
    function unReserveStream(
        uint256 _id,
        uint8 _priority
    ) external {
        require(accountData[msg.sender].alive, "Account not setup for reservations");
//        // make sure the stream is alive
//        require(gets[msg.sender][_id].cps != 0, "stream must be alive");
        // clear data currently held
        delete accountData[msg.sender].reservationData[_priority][gets[msg.sender][_id].coinIndex];
    }

    /// @notice gets how much is already reserved and says if an amount is possible or not
    function calcEarMarked(
        address _payer,
        uint8 _index, /*how many streams*/
        uint256 _asking,
        bool _max,
        IalcV2Vault _v2Vault
    ) public returns (uint256 _canBorrow){
        // gets the amount of coins that have been reserved
        if(accountData[_payer].alive){
            // todo: fix (steal code from simpleSummedArrs)
            _canBorrow = 0;
        }
        // local storage of variable to reduce gas
        uint256 _allowance = _v2Vault.allowance(_payer);
        // avoids underflow
        _canBorrow = _allowance >= _canBorrow ? _allowance - _canBorrow : 0;
    }

    /// @notice swaps the index of 2 reserved streams to change priority
    /// @param _id1 the id of the 1st stream
    /// @param _id2 the id of the 2nd stream
    function swapResStreams(
        uint256 _id1,
        uint256 _id2,
        uint8 _resIndex1,
        uint8 _resIndex2,
        uint8 _coinIndex
    ) external {
        require(accountData[msg.sender].alive);
        require(coinData[_coinIndex].valid);
        // ensures proper ordering of data
        require(gets[msg.sender][_id1].reserveIndex < maxIndex);
        require(gets[msg.sender][_id2].reserveIndex < maxIndex);
        // makes sure that they share the coin type
        require(gets[msg.sender][_id1].coinIndex == gets[msg.sender][_id2].coinIndex);
        // makes sure that the data lines up
        require(
            (accountData[msg.sender].reservationData[_resIndex1][_coinIndex] ==
            gets[msg.sender][_id1].reserveIndex) &&
            (accountData[msg.sender].reservationData[_resIndex2][_coinIndex] ==
            gets[msg.sender][_id2].reserveIndex));
        // performs the swap
        accountData[msg.sender].reservationData[_resIndex1][_coinIndex] = _id2;
        accountData[msg.sender].reservationData[_resIndex2][_coinIndex] = _id1;
        gets[msg.sender][_id1].reserveIndex = _resIndex2;
        gets[msg.sender][_id2].reserveIndex = _resIndex1;
    }

    /// @dev allows the admin to approve new coins to be used with streamPay
    /// @param _alcV2vault address of the alcVault
    /// @param _alAsset address of the alAsset
    /// @param _index of the new data
    function setCoinIndex(
        IalcV2Vault _alcV2vault,
        IERC20 _alAsset,
        uint8 _index
    ) external adminOnly {
        // @pre_audit_checks mby do some interface checks?
        require((address(_alcV2vault) != address(0)) && (address(_alAsset) != address(0)));
        coinData[_index] = Coin(_alcV2vault, _alAsset, true);
    }

    /// @dev allows the admin to approve new coins to be used with streamPay
    /// @param _route new route
    /// @param _index index of the new
    function setRouteIndex(
        address[] memory _route,
        uint256 _index
    ) external {
        // @pre_audit_checks mby do some interface checks?
        require(hasRole(ROUTE_ADMIN, msg.sender), "router daddy only");
        require(_index != 0, "cannot override the no route option");
        // the only way you can edit a route is to kill it, reverting it back to its base state
        require((routes[_index].length == 0) || (_route.length == 0), "cannot edit route");
        routes[_index] = _route;
    }

    /// @notice returns the total payout for the stream
    /// @dev returns max int (2**256-1) if it has no end
    /// @param _payer the address that is paying out the funds
    /// @param _id the id number of the stream
    function calcTotalPayOut(
        address _payer,
        uint256 _id
    ) public view returns(uint256) {
        return gets[_payer][_id].end == 0 ? 2**256-1 :
        ((gets[_payer][_id].end - gets[_payer][_id].sinceLast) * gets[_payer][_id].cps);
    }

    /// @notice returns some place holder data for use off chain
    /// @dev take this number and / by av daily returns
    /// @param _payer the address that is paying out the funds
    function calcRunwayLeft(
        address _payer,
        uint8 _coinIndex,
        IalcV2Vault _v2Vault
    ) external returns (uint256 _available, uint256 _totalCps){
        _available = calcEarMarked(
            _payer,
            maxIndex,
            0,
            true,
            _v2Vault);
        _totalCps = accountData[_payer].totalCPS[_coinIndex];
    }

    /// makes account if there isn't one
    function startReservation(
    ) external {
        require(accountData[msg.sender].alive);
        accountData[msg.sender].alive = true;
    }

    function destroyStreamPay(
        address payable _to
    ) external adminOnly {
        selfdestruct(_to);
    }

    error AdminOnly(address account);

    modifier adminOnly {
        // only admin address can call this (could be changed to the multisig or DAO)
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert AdminOnly({account: msg.sender});
        }
        _;
    }

    event STREAM_STARTED (
        address indexed from,
        uint256 indexed ID,
        address indexed to
    );

    event STREAM_CLOSED (
        address indexed from,
        uint256 indexed ID
    );

    event CHANGED_ALC_V2 (
        address indexed newAddr
    );

    event COIN_ADDR_CHANGED (
        address indexed newAddr
    );

    event ADMIN_CHANGED (
        address indexed newAddr
    );

    event STREAM_COLLECTED(
        address payer,
        uint256 amount
    );
}
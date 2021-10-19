// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IpeepoPay is IAccessControl {

    // the struct that represents the data stored in each stream
    struct Stream {
        address payee;
        uint256 cps;
        uint256 sinceLast;
        uint256 freq;
        uint256 end;
        address[] route;
        bytes32 ROLE;
    }

    // returns the address of the alcV2 contract
    function adrAlcV2 (
    ) external view returns (
        address
    );

    // allows the address with the DEFAULT_ADMIN_ROLE to update who the admin is
    function changeAdmin (
        address _new
    ) external;

    // allows the address with the DEFAULT_ADMIN_ROLE to update where the alcV2 contract is stored
    function changeAlcV2 (
        address _new
    ) external;

    // allows the caller to close the stream of a specific ID
    function closeStream (
        uint256 _id
    ) external;

    // returns the address of the coin it will receive from V2 that it is borrowing against
    function coinAddress (
    ) external view returns (
        address
    );

    // allows the address with the DEFAULT_ADMIN_ROLE to update the address of the coin
    function setCoinAddress (
        address _new
    ) external;

    // allows the caller to create a stream
    function createStream (
        address _to,
        uint256 _cps,
        uint256 _freq,
        uint256 _start,
        uint256 _end,
        address[] memory _route
    ) external;

    // allows anyone with the permissions to, to collect the stream to the router to what ever address its directed to
    function drawDownStream (
        address _payer,
        uint256 _ID
    ) external returns (
        bool success
    );

    // used in the creation of streams and the updating of permissions
    function genRole (
        address _from,
        uint256 _ID,
        Stream memory _stream
    ) external pure returns (
        bytes32 _ROLE
    );

    // returns the stream that exists within the mapping
    function gets (
        address, uint256
    ) external view returns (
        address payee,
        uint256 cps,
        uint256 sinceLast,
        uint256 freq,
        uint256 end,
        bytes32 ROLE
    );

    // role based permissioning to set who can call the collect streams function for another address
    function streamPermGrant (
        uint256 _ID,
        address _account
    ) external;
    function streamPermRevoke (
        uint256 _ID,
        address _account
    ) external;

    // returns how much as address with receive from an individual stream (pre custom contract routing)
    function streamSize (
        address _payer,
        uint256 _ID
    ) external view returns (
        uint256 _amount
    );

    // returns the number of streams an address is paying out on
    function streams (
        address
    ) external view returns (
        uint256
    );
}
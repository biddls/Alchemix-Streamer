// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IpeepoPay {
    // admin stuff
    function changeAlcV2 (
        address _new
    ) external;

    function setCoinAddress (
        address _new
    ) external;

    function changeAdmin (
        address _new
    ) external;

    // data stuff
    function adrAlcV2 (
    ) external view returns (address);
    function vault (
    ) external view returns (address);
    function coinAddress (
    ) external view returns (address);
    function admin (
    ) external view returns (address);

    // streams
    function createStream (
        uint256 _cps,
        address _to,
        uint256 _freq,
        uint256 _start,
        uint256 _end,
        bool _now,
        address[] memory _route
    ) external;

    function closeStream (
        uint256 _id
    ) external;

    function drainStreams (
        address[] memory _payers,
        uint256[] memory _IDs,
        uint256[] memory _amounts
    ) external;

    function drainStream (
        address _payer,
        uint256 _ID,
        uint256 _amount
    ) external;

    function gets (
        address,
        uint256
    ) external view returns (
        address payee,
        uint256 cps,
        uint256 sinceLast,
        uint256 freq
    );

    function streams (
        address
    ) external view returns (uint256);
}
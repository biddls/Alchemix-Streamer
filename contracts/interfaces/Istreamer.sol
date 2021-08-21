// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface Istreamer {
    // admin stuff
    function changeAlcV2 ( // TESTED
        address _new
    ) external;

    function setCoinAddress ( // TESTED
        address _coinAddress
    ) external;

    function changeAdmin ( // TESTED
        address _to
    ) external;

    // data stuff
    function adrAlcV2() external; // TESTED
    function coinAddress() external; // TESTED
    function admin() external; // TESTED

    // streams
    function creatStream( // TESTED
        uint256 _cps,
        address _to,
        uint256 _freq,
        bool _openDrawDown,
        address[] memory _approvals
    ) external;

    function closeStream( // TESTED
        address _to
    ) external;

    // draw down from stream
    function drainStreams(
        address _to,
        address[] memory _arrayOfStreamers,
        uint256[] memory _amounts
    ) external;

    // approval management
    function revokeApprovals(
        address _fromAddr,
        address[] memory _addresses
    ) external;

    function grantApprovals(
        address _fromAddr,
        address[] memory _addresses
    ) external;
}
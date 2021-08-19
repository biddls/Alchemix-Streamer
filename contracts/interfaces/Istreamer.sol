// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface Istreamer {
    // admin stuff
    function changeAlcV2 (address _new) external;
    function setCoinAddress (address _coinAddress) external;
    function changeAdmin (address _to) external;

    // data stuff
    function adrAlcV2() external;
    function coinAddress() external;
    function admin() external;

    // create stream
    function creatStream(uint256 _cps, address _to) external;

    // close stream
    function closeStream(address _to) external;

    // draw down from stream
    function drawDown() external;
}
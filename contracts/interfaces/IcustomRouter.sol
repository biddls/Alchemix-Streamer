// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IcustomRouter {
    function route(address _coinAddr, address _to, uint256 _amount, address[] memory _route, uint256 current) external;
}
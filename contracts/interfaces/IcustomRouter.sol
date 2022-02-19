// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IcustomRouter {
    // the a
    function route(
        IERC20 _coinAddr, // the address of the erc-20 coin that it will move
        address _to, // the end address
        uint256 _amount, // the amount of coins the contract received
        address[] memory _route, // the list of contract names that the money goes through
        uint256 current // the index of where in the list the contract is
    ) external;
}
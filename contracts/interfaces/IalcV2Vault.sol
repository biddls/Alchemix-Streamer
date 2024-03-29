// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IalcV2Vault {
    // gets called from the user to approve an address to withdraw on its behalf
    function approve(
        address borrower,
        uint256 amount)
    external;

    // borrows the coins from the vault
    function mintFrom(
        address cdpOwner,
        uint256 amount,
        address recipient
    ) external;

    // returns the max allowance allowed to be borrowed from the fake V2 contract
    function allowance(
        address
    ) external
    view returns ( uint256 );

}
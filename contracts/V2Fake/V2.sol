// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ERC_20_EXTERNAL_MINTER} from "./ERC_20_EXTERNAL_MINTER.sol";

contract V2 {
    address public admin;
    ERC_20_EXTERNAL_MINTER public alAsset;

    mapping(address => uint256) public allowance;

    constructor (){
        admin = msg.sender;
        alAsset = new ERC_20_EXTERNAL_MINTER(0, 18, "alAsset", "alAsset fake temp token");
        alAsset.updateMinter(address(this));
    }

    // gets called from the user to approve an address to withdraw on its behalf
    function approve(
        address borrower,
        uint256 amount)
    external {}

    // borrows the coins from the vault
    function mintFrom(
        address cdpOwner,
        uint256 amount,
        address recipient
    ) external {
        require(allowance[cdpOwner] >= amount, "allowance not large enough");
        alAsset.externalMint(amount, recipient);
        allowance[cdpOwner] -= amount;
    }

    function setLimit(uint256 _amount) external {
        allowance[msg.sender] = _amount;
    }
}

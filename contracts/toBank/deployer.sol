// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./router.sol";

contract deployer {

    router internal _routerCont;

    address public routerAddr;
    address public alAsset;
    address public AMM;
    address public Tusd;
    address public admin;

    constructor () {
        admin = msg.sender;
    }

    function makeRouter (address _sendTusdTo) external{
        require(_sendTusdTo != address(0), "can't route to 0 addr");
        new router(routerAddr, alAsset, AMM, Tusd, _sendTusdTo);
    }

    // admin
    function change_routerAddr(address _to) external {
        require(_to != address(0));
        require(msg.sender == admin);
        routerAddr = _to;
    }
    function change_alAsset(address _to) external {
        require(_to != address(0));
        require(msg.sender == admin);
        alAsset = _to;
    }
    function change_AMM(address _to) external {
        require(_to != address(0));
        require(msg.sender == admin);
        AMM = _to;
    }
    function change_Tusd(address _to) external {
        require(_to != address(0));
        require(msg.sender == admin);
        Tusd = _to;
    }
    function change_admin(address _to) external {
        require(_to != address(0));
        require(msg.sender == admin);
        admin = _to;
    }
}

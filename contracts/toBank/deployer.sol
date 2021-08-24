pragma solidity ^0.8.0;

import "./router.sol";

contract deployer {

    router public routerContract;

    address public router;
    address public alUSD;
    address public AMM;
    address public Tusd;
    address public admin;

    constructor () {
        admin = msg.sender;
    }

    function makeRouter(address _bankAddr){
        require(_bankAddr != address(0), "can't route to 0 addr");
        new router(router, alUSD, AMM, Tusd, _bankAddr);
    }

    // admin
    function change_router(address _to) external {
        require(_to != address(0));
        require(msg.sender == admin);
        router = _to;
    }
    function change_alUSD(address _to) external {
        require(_to != address(0));
        require(msg.sender == admin);
        alUSD = _to;
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
    function change_sendTusdTo(address _to) external {
        require(_to != address(0));
        require(msg.sender == admin);
        sendTusdTo = _to;
    }
    function change_admin(address _to) external {
        require(_to != address(0));
        require(msg.sender == admin);
        admin = _to;
    }
}

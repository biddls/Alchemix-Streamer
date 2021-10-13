// SPDX-License-Identifier: UNLICENSED
// i can just use the custom contract routing features instead
pragma solidity ^0.8.0;

// import streamer
import {IpeepoPay} from ".././interfaces/IpeepoPay.sol";

// import alusd interface
// import Tusd interface
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import AMM interface

// import trust wallet interface


contract router{

    address public streamer;
    address public alUSD;
    address public AMM;
    address public Tusd;
    address public sendTusdTo;

    constructor(
        address _streamer,
        address _alUSD,
        address _AMM,
        address _Tusd,
        address _sendTusdTo){

        streamer = _streamer;
        alUSD = _alUSD;
        Tusd = _Tusd;
        AMM = _AMM;
        sendTusdTo = _sendTusdTo;
        emit routeCreated(address(this));
    }

    function route (
        address[] memory _arrayOfStreamers,
        uint256[] memory _amounts) external {

        // drain streams
        (bool success, ) =
        address(streamer).call(
            abi.encodePacked(
                IpeepoPay.drawDownStream.selector,
                abi.encode(address(this), _arrayOfStreamers, _amounts)));

        require(success, "Draw down failed");

        // do AMM swap now


        // send to bank account
        IERC20(Tusd).transfer(sendTusdTo, IERC20(Tusd).balanceOf(address(this)));
    }

    event routeCreated(
        address contAddr
    );
}
pragma solidity ^0.8.0;

// import streamer
import ".././interfaces/Istreamer.sol";

// import alusd interface
// import Tusd interface
import ".././node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import AMM interface

// import trust wallet interface


contract router is IERC20, Istreamer{

    address public router;
    address public alUSD;
    address public AMM;
    address public Tusd;
    address public sendTusdTo;

    constructor(address _router,
        address _alUSD,
        address _AMM,
        address _Tusd,
        address _sendTusdTo){

        router = _router;
        alUSD = _alUSD;
        Tusd = _Tusd;
        AMM = _AMM;
        sendTusdTo = _sendTusdTo;
        emit routeCreated(address(this));
    }

    function route (
        address[] memory _arrayOfStreamers,
        uint256[] memory _amounts) external {
        uint256[streamsFrom.length] memory _amounts;

        (bool success, bytes memory returnDataAlAsset) =
        address(router).call(
            abi.encodePacked(
                Istreamer.mintFrom.selector,
                abi.encode(address(this), _arrayOfStreamers, _amounts)));

        require(success, "Draw down failed");

        // do AMM swap now

        // send to bank account

        emit routed(returnDataAlAsset, returnDataAsset);
    }

    event routeCreated(
        address contAddr
    );

    event routed(
        bytes memory,
        bytes memory
    );
}
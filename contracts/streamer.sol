pragma solidity ^0.8.0;

// import Ialc_valut_v2.sol;
// import Ierc-20.sol

contract streamer {
    // creates a many to many bi-directionally lookup-able data structure
    // from -> to
    mapping(address => address[]) public fromTo;
    // to -> from
    mapping(address => address[]) public toFrom;
    // how much an address gets
    // fromAdr -> toAdr -> amount
    mapping(address => mapping(address => stream)) public gets;

    struct stream{
        uint256 cps;
        uint256 sinceLast;
    }
    // address of alcV2
    address public adrAlcV2;

    // address of erc-20 coin used
    address public coinAddress;

    // address of the admin
    address public admin;

    constructor () {
        admin = msg.sender;
    }

    function changeAlcV2 (address _new) external {
        require(msg.sender == admin, "admin only");
        adrAlcV2 = _new;
    }

    function setCoinAddress (address _coinAddress) external {
        require(msg.sender == admin, "admin only");
        coinAddress = _coinAddress;
    }

    function changeAdmin (address _to) external {
        require(msg.sender == admin, "admin only");
        require(_to != address(0));
        admin == _to;
    }

    // create stream
    function creatStream(uint256 _cps, address _to) external {
        require(_to != address(0), "cannot stream to 0 address");
        require(_cps > 0, "should not stream 0 coins");
        // fromTo
        fromTo[msg.sender].push(_to);
        // toFrom
        toFrom[_to].push(msg.sender);
        // gets
        gets[msg.sender][_to] = stream(_cps, block.timestamp);
    }

    // close stream
    function closeStream(address _to) external {
        require(_to != address(0), "cannot stream to 0 address");
        // gets
        gets[msg.sender][_to] = stream(0, block.timestamp);
    }

    // draw down from stream
    function drawDown() external {
        uint256 total;
        uint256 change;
        for(uint256 i=0; i < toFrom[msg.sender].length; i++){
            change = block.timestamp - gets[toFrom[msg.sender][i]][msg.sender].sinceLast;
            total += change * gets[toFrom[msg.sender][i]][msg.sender].cps;
        }
        // transfer the funds here
    }
}
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/*
this is just a test contract for the custom routing
all it does is revert
*/

contract Reverts {
    // main function that gets called to activate the next step
    function route(address _coinAddr, address _to, uint256 _amount, address[] memory _route, uint256 _current) external{
        // Put code here that is run regardless of position in the route
        if(_route.length > _current){
            require(_route[_current] != address(this), "Cannot route to self");
            // put something here if you are running code in the middle of the route
            (bool success, bytes memory returnData) = address(_route[_current]).call(
                abi.encodePacked(
                    this.route.selector,
                    abi.encode(_coinAddr, _to, _amount, _route, _current + 1)));
            require(success, string(returnData));
            revert();
            /*
            if your being a good shadowy super coder put something here that checks that the next step in the route
            moved the funds on so things are less likely to fail successfully e.g.
            */
        } else {
            // put code here if you are running code as the last step in the route
            revert();
        }
    }
}

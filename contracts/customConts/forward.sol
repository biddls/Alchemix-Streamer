// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/*
this is just a test contract for the custom routing
all it does is pass on the coins to the next address
*/

// import any interfaces you need
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Forward { //call it what ever you want
    // main function that gets called to activate the next step
    function route(address _coinAddr, address _to, uint256 _amount, address[] memory _route, uint256 _current) external{
        // Put code here that is run regardless of position in the route
        if(_route.length > _current){
            // put something here if you are running code in the middle of the route
            IERC20(_coinAddr).transfer(_route[_current], _amount);
            require(_route[_current] != address(this), "Cannot route to self");
            (bool success, bytes memory returnData) = address(_route[_current]).call(
                abi.encodePacked(
                    this.route.selector,
                    abi.encode(_coinAddr, _to, _amount, _route, _current + 1)));
            require(success, string(returnData));
            // if your being a good shadowy super coder put something here that checks that the next step in the route
            // moved the funds on so things are less likely to fail successfully e.g.
            require(IERC20(_coinAddr).balanceOf(_route[_current]) == 0, "next did not pass on coins");
            require(IERC20(_coinAddr).balanceOf(address(this)) == 0, "this cont did not pass on all coins");
        } else {
            // put code here if you are running code as the last step in the route
            IERC20(_coinAddr).transfer(_to, IERC20(_coinAddr).balanceOf(address(this)));
            require(IERC20(_coinAddr).balanceOf(address(this)) == 0, "this cont did not pass on all coins");
        }
    }
}
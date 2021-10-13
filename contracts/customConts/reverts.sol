// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/*
this is just a test contract for the custom routing
*/
contract Reverts {
    function route(address _coinAddr, address _to, uint256 _amount, address[] memory _route, uint256 _current) external{
        if(_route.length > _current){
            (bool success, bytes memory returnData) = address(_route[0]).call(
                abi.encodePacked(
                    this.route.selector,
                    abi.encode(_coinAddr, _to, _amount, _route, _current++)));
            require(success);
        }
        revert();
    }
}

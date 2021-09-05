// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IcustomRouter} from ".././interfaces/IcustomRouter.sol";

/*
this is just a test contract for the custom routing
*/

contract forwardBroken {
    function route(address _coinAddr, address _to, uint256 _amount, address[] memory _route, uint256 _current) external{
        if(_route.length > _current){
            IcustomRouter(_route[0]).route(_coinAddr, _to, _amount, _route, _current++);
        }
    }
}

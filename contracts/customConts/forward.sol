// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import ".././interfaces/IERC_20_EXTERNAL_MINTER.sol";
import {IcustomRouter} from ".././interfaces/IcustomRouter.sol";

/*
this is just a test contract for the custom routing
*/

contract forward {
    function route(address _coinAddr, address _to, uint256 _amount, address[] memory _route, uint256 _current) external{
        IERC_20_EXTERNAL_MINTER(_coinAddr).transfer(_to, _amount);
        if(_route.length > _current){
            IcustomRouter(_route[0]).route(_coinAddr, _to, _amount, _route, _current++);
        }
    }
}

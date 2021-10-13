#Custom Contract Routing

---

###Route Function
```solidity
function route(
    address _coinAddr,
    address _to,
    uint256 _amount,
    address[] memory _route,
    uint256 current
) external;
```
 - `_coinAddr`: the address of the erc-20 coin that it has received
 - `_to`: the end address of who will receive the coins
 - `_amount`: the amount of coins the contract received from the previous step
 - `_route`: the list of contract addresses that the money goes through 
 - `current`: the index of where in the list the contract is so it knows how to get the address of the next contract

###But you don't need to worry about that:
If your going to make a chain in the contract all you need to worry about is as follows. Take a basic Route contract:

```solidity
pragma solidity ^0.8.0;

// import any interfaces you need
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ContFoo { //call it what ever you want
    // main function that gets called to activate the next step
    function route(address _coinAddr, address _to, uint256 _amount, address[] memory _route, uint256 _current) external{
        // Put code here that is run regardless of position in the route
        if(_route.length > _current + 1){
            // put something here if you are running code in the middle of the route
            (bool success, bytes memory returnData) = address(_current++).call(
                abi.encodePacked(
                    this.route.selector,
                    abi.encode(_coinAddr, _to, _amount, _route, _current++)));
            require(success);
            // if your being a good shadowy super coder put something here that checks that the next step in the route
            // moved the funds on so things are less likely to fail successfully e.g.
            require(IERC20(_coinAddr).balanceOf(_route[_current++]) == 0);
        } else {
            // put code here if you are running code as the last step in the route
        }
    }
}
```
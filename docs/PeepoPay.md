<h1>Better capital efficiently, Better memes, PeepoPay</h1>

<h2>PeepoPay comprises of 3 main functions:</h2>

 - [Create Stream](#h3create-streamh3)  
 - [Collect Stream](#h3collect-streamh3)  
 - [Close Stream](#h3close-streamh3)

#<h3>Create Stream</h3>

Stream comprises of 6 Parts and be set up by anyone:  
1. `to`: Who you're sending the money to  
2. `cps`: How much money your sending per second  
3. `freq`: How often the receiver has access to the money `0 = all the time ; 604800 = once per week`  
4. `start`: When the stream starts in UNIX time `allows for queuing up of streams or back pay`   
5. `end`: When does the stream end in UNIX time `0 = never ends (but can be closed by the payer at any time)`
6. `route`: Allows the chaining of contracts to do the same set of steps each time the stream is drawn down

#<h3>Collect Stream</h3>

Collecting the stream has 2 main parts:
1. `V2`: This draws down the funds and then sends them to the receiver if they don't have a route, but if they do have 
   a route then it sends it to the 1st contract on the route
2. `Route`: If there is a route to be taken then it calls the first contract, see: [Custom Contract Router](./Custom%20Contract%20Router.md)

#<h3>Close Stream</h3>

This deletes all data from the listing from the contract so meaning everything goes to 0; meaning no coins can be 
emitted, and it would route to the 0 address by default

<h2>Integrating PeepoPay into your contract in 3 simple steps:</h2>

1. Download interface file from [here](./../contracts/interfaces/IpeepoPay.sol)
2. Get the contract address from [here](./ContractAddresses.md)
3. Begin making function calls to the contract and remeber the risk of re-enterancy with the custom contract routing
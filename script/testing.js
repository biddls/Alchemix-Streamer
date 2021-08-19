const {BigNumber} = require("ethers");
const testing = async function() {
    // setup
    let [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    const balance = await owner.getBalance();

    // testing stuff
    let contract = await ethers.getContractFactory("streamer");
    const streamer = await contract.deploy();

    return {
        streamer: streamer,
        balance: balance,
        owner: owner,
        addr1: addr1,
        addr2: addr2,
        addr3: addr3,
        addrs: addrs
    };
}

module.exports = {
    testing
}
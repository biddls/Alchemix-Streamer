const {BigNumber} = require("ethers");
const testing = async function() {
    // setup
    let [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    const balance = await owner.getBalance();

    // testing stuff
    // streamer
    let contract = await ethers.getContractFactory("streamer");
    const streamer = await contract.deploy();

    // streamer.changeAlcV2(addr1.address);
    // streamer.setCoinAddress(addr2.address);
    // streamer.changeAdmin(addr3.address);

    // deployer
    contract = await ethers.getContractFactory("deployer");
    const deployer = await contract.deploy();

    return {
        streamer,
        deployer,
        balance,
        owner,
        addr1,
        addr2,
        addr3,
        addrs
    };
}

module.exports = {
    testing
}
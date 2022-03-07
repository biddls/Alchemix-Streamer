const {BigNumber} = require("ethers");

const testing = async function() {
    // setup
    let [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    const balance = await owner.getBalance();

    // streamer
    let contract = await ethers.getContractFactory("StreamPay");
    const streamPay = await contract.deploy(5);

    // // deployer
    // contract = await ethers.getContractFactory("Deployer");
    // const deployer = await contract.deploy();

    //testing custom conts
    contract = await ethers.getContractFactory("Forward");
    const forward = await contract.deploy();
    contract = await ethers.getContractFactory("Forward");
    const forward2 = await contract.deploy();
    contract = await ethers.getContractFactory("ForwardBroken");
    const forwardBroken = await contract.deploy();
    contract = await ethers.getContractFactory("Reverts");
    const reverts = await contract.deploy();

    // fake V2 contract
    contract = await ethers.getContractFactory("V2");
    const v2 = await contract.deploy();

    // external minter contract
    contract = await ethers.getContractFactory("ERC_20_EXTERNAL_MINTER");
    const alAsset = await contract.attach(
        await v2.alAsset()// The deployed contract address
    );


    // getting stuff up to plug into one another
    // into V2
    streamPay.setCoinIndex(v2.address, alAsset.address, 0);
    streamPay.grantRole(await streamPay.ROUTE_ADMIN(), owner.address);

    return {
        streamPay,
        // deployer,
        forward,
        forward2,
        forwardBroken,
        reverts,
        v2,
        alAsset,
        balance,
        owner,
        addr1,
        addr2,
        addr3,
        addrs
    };
}

const testingGeneral = async function(decimals) {
    let [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    const balance = await owner.getBalance();

    // my stuff
    let Token = await ethers.getContractFactory('ERC_20_EXTERNAL_MINTER');
    const TEST = await Token.deploy(10000, decimals, "test", "TST");

    await TEST.updateMinter(owner.address); // sets the external minter

    return {balance: balance,
        TEST: TEST,
        owner: owner,
        addr1: addr1,
        addr2: addr2,
        addrs: addrs};
}


const testingSimpleSummedArrs = async function(_maxSteps) {
    let [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    const balance = await owner.get

    let Token = await ethers.getContractFactory('SimpleSummedArrays');

    const ssa = await Token.deploy(_maxSteps, [owner.address, addr1.address]);

    return {balance,
        ssa,
        owner,
        addr1,
        addr2,
        addrs};
}

module.exports = {
    testing,
    testingGeneral,
    testingSimpleSummedArrs
}
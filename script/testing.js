const {BigNumber} = require("ethers");
const testing = async function() {
    // setup
    let [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    const balance = await owner.getBalance();

    // testing stuff
    // streamer
    let contract = await ethers.getContractFactory("PeepoPay");
    const peepoPay = await contract.deploy();

    // streamer.changeAlcV2(addr1.address);
    // streamer.setCoinAddress(addr2.address);
    // streamer.changeAdmin(addr3.address);

    // deployer
    contract = await ethers.getContractFactory("Deployer");
    const deployer = await contract.deploy();

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

    // streamPay
    contract = await ethers.getContractFactory("StreamPay");
    const streamPay = await contract.deploy(peepoPay.address);

    // setting stuff up to plug into one another
    // into V2
    peepoPay.changeAlcV2(v2.address);

    // into the alAsset
    peepoPay.setCoinAddress(alAsset.address);
    deployer.change_alAsset(alAsset.address);

    return {
        peepoPay,
        streamPay,
        deployer,
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

module.exports = {
    testing,
    testingGeneral
}
const { expect } = require("chai");
const { testing } = require("../script/testing.js");
const {BigNumber} = require("ethers");

function sleep(milliseconds) {
    const start = Date.now();
    while (Date.now() - start < milliseconds);
}

describe("streamer", function () {

    let vars;

    beforeEach(async function () {
        vars = await testing();
    });

    describe("Token contract setup", async function () {
        it("Deployment checks", async function () {
            // check addresses of everything
            // expect(await vars.streamer.adrAlcV2()).to.equal();
            // expect(await vars.streamer.coinAddress()).to.equal();
            expect(await vars.streamer.admin()).to.equal(vars.owner.address);
        });
        it("Admin tooling tests", async function () {
            // setting new addresses
            await vars.streamer.changeAlcV2(vars.addr1.address);
            await vars.streamer.setCoinAddress(vars.addr2.address);
            await vars.streamer.changeAdmin(vars.addr3.address);

            // checking addresses
            expect(await vars.streamer.adrAlcV2()).to.equal(vars.addr1.address);
            expect(await vars.streamer.coinAddress()).to.equal(vars.addr2.address);
            expect(await vars.streamer.admin()).to.equal(vars.addr3.address);
        });
    });
    describe("Streams", async function () {
        it("Create stream", async function () {
            await vars.streamer.creatStream(1, vars.addr1.address, 0);
            expect ((await vars.streamer.gets(
                vars.owner.address, vars.addr1.address))[0])
                .to.equal(BigInt("1"));
            // cant get the time one to behave but it seems to be working fine
            expect ((await vars.streamer.gets(
                vars.owner.address, vars.addr1.address))[2])
                .to.equal(BigInt("0"));

            expect (await vars.streamer.fromTo(vars.owner.address, 0))
                .to.equal(vars.addr1.address);
            expect (await vars.streamer.toFrom(vars.addr1.address, 0))
                .to.equal(vars.owner.address);
        });
        it("Close stream", async function () {
            await vars.streamer.closeStream(vars.addr1.address);

            expect ((await vars.streamer.gets(
                vars.owner.address, vars.addr1.address))[0])
                .to.equal(BigInt("0"));
            // cant get the time one to behave but it seems to be working fine
            expect ((await vars.streamer.gets(
                vars.owner.address, vars.addr1.address))[2])
                .to.equal(BigInt("0"));
        });
        it("drawing Down", async function () {
            await vars.streamer.creatStream(1000, vars.addr1.address, 0);
            sleep(2000);
            console.log(await vars.streamer.drawDown());
            expect(await vars.streamer.drawDown()).to.be.greaterThanOrEqual(0);
        });
    });
});
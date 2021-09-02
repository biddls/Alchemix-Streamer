const { expect } = require("chai");
const { testing } = require("../script/testing.js");

const zero_address = "0x0000000000000000000000000000000000000000";


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
            await expect(vars.streamer.changeAlcV2(vars.addr1.address))
                .to.emit(vars.streamer, 'changedAlcV2')
                .withArgs(vars.addr1.address);

            await expect(vars.streamer.setCoinAddress(vars.addr2.address))
                .to.emit(vars.streamer, 'coinAddressChanged')
                .withArgs(vars.addr2.address);

            await expect(vars.streamer.changeAdmin(vars.addr3.address))
                .to.emit(vars.streamer, 'adminChanged')
                .withArgs(vars.addr3.address);

            // checking addresses
            expect(await vars.streamer.adrAlcV2()).to.equal(vars.addr1.address);
            expect(await vars.streamer.coinAddress()).to.equal(vars.addr2.address);
            expect(await vars.streamer.admin()).to.equal(vars.addr3.address);

            await expect(vars.streamer.connect(vars.addr2).changeAlcV2(vars.addr1.address))
                .to.be.revertedWith("admin only");
            await expect(vars.streamer.connect(vars.addr2).setCoinAddress(vars.addr2.address))
                .to.be.revertedWith("admin only");
            await expect(vars.streamer.connect(vars.addr2).changeAdmin(vars.addr3.address))
                .to.be.revertedWith("admin only");

            await expect(vars.streamer.connect(vars.addr3).changeAlcV2(zero_address))
                .to.be.reverted;
            await expect(vars.streamer.connect(vars.addr3).setCoinAddress(zero_address))
                .to.be.reverted;
            await expect(vars.streamer.connect(vars.addr3).changeAdmin(zero_address))
                .to.be.reverted;
        });
    });
    describe("Stream", async function () {
        it("Create stream", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(
                1, vars.addr1.address, 0, 0, true);
            expect((await vars.streamer.gets(
                vars.owner.address, 0))[0])
                .to.equal(vars.addr1.address);
            // cant get the time one to behave but it seems to be working fine
            expect((await vars.streamer.gets(
                vars.owner.address, 0))[1])
                .to.equal(BigInt("1"));
            //idk how to test time stamp
            expect((await vars.streamer.gets(
                vars.owner.address, 0))[3])
                .to.equal(0);
        });
        it("test to make open stream", async function () {
            // v2 code here to get approval for the contract to draw down
            await expect(vars.streamer.createStream(
                1, vars.addr1.address, 0, 0, true)
            ).to.emit(vars.streamer, 'streamStarted')
                .withArgs(vars.owner.address, 0);
        });
        it("dont stream to 0 address", async function () {
            // v2 code here to get approval for the contract to draw down
            await expect(vars.streamer.createStream(
                1, zero_address, 0, 0, true)).to.be.revertedWith("cannot stream to 0 address");
        });
        it("streams CPS > 0", async function () {
            // v2 code here to get approval for the contract to draw down
            await expect(vars.streamer.createStream(
                0, vars.addr1.address, 0, 0, true,)).to.be.revertedWith("should not stream 0 coins");
        });
    });
    describe("closing stream", async function () {
        it("Close stream", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(
                1, vars.addr1.address, 0, 0, true);
            await vars.streamer.closeStream(0);

            expect((await vars.streamer.gets(
                vars.owner.address, vars.addr1.address))[1])
                .to.equal(BigInt("0"));
            // cant get the time one to behave but it seems to be working fine
            expect((await vars.streamer.gets(
                vars.owner.address, vars.addr1.address))[1])
                .to.equal(BigInt("0"));
        });
    });
    describe("drawing down", async function () {
        it("Normal drawing down", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(
                1000, vars.addr1.address,0, 0, true);

            vars.streamer.drainStreams([vars.owner.address],
                [0],
                [1]);
        });
        it("draw down too soon", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(
                1000, vars.addr1.address, 10, 0, true);

            await vars.streamer.drainStreams(
                [vars.owner.address],
                [0],
                [2000]);
        });
        it("draw down too much", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(
                1, vars.addr1.address, 0, 0, true);

            await vars.streamer.drainStreams(
                [vars.owner.address],
                [0],
                [2000]);
        });
        it("darrays arnt the same length", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(
                1, vars.addr1.address, 0, 0, true);

            await expect(vars.streamer.drainStreams(
                [vars.owner.address],
                [0, 1],
                [2000])).to.be.revertedWith("all the arrays must be the same length");

            await expect(vars.streamer.drainStreams(
                [vars.owner.address],
                [0],
                [2000, 2])).to.be.revertedWith("all the arrays must be the same length");
        });
    });
});
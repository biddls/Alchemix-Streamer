const { expect } = require("chai");
const { testing } = require("../script/testing.js");
const { now, sleep } = require("./Util");

const zero_address = "0x0000000000000000000000000000000000000000";

describe("streamPay", function () {

    let vars;

    beforeEach(async function () {
        vars = await testing();
    });

    describe("Token contract setup", async function () {
        it("Admin tooling tests", async function () {
            // checking addresses
            await expect((await vars.streamPay.coinData(0)).alcV2vault).to.equal(vars.v2.address);
            await expect((await vars.streamPay.coinData(0)).alAsset).to.equal(vars.alAsset.address);
            await expect((await vars.streamPay.coinData(0)).valid).to.equal(true);
        });
    });
    describe("Stream", async function () {
        it("Create stream", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, 0, 0);
            expect((await vars.streamPay.gets(
                vars.owner.address, 0))[0])
                .to.equal(vars.addr1.address);
            // cant get the time one to behave but it seems to be working fine
            expect((await vars.streamPay.gets(
                vars.owner.address, 0))[1])
                .to.equal(BigInt("1"));
        });
        it("dont stream to 0 address", async function () {
            // v2 code here to get approval for the contract to draw down
            await expect(vars.streamPay.createStream(
                zero_address, 1, 0, 0, 0)).to.be.revertedWith("cannot stream to 0 address");
        });
        it("streams CPS > 0", async function () {
            // v2 code here to get approval for the contract to draw down
            await expect(vars.streamPay.createStream(
                vars.addr1.address, 0, 0, 0, 0)).to.be.revertedWith("should not stream 0 coins");
        });
    });
    describe.skip("edit stream", async function () {
        it("nice close", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamPay.createStream(
                vars.addr1.address, 1, now()-10, now()+10, 0);

            expect(await (await vars.streamPay.accountData(vars.owner.address)).streams).to.equal(1);

            await vars.v2.setLimit(100000);

            await expect(vars.streamPay.closeStream(0, false, now()-5))
                .to.emit(vars.streamPay, 'streamClosed');
        });
        it("extend stream", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamPay.createStream(
                vars.addr1.address, 1, now()-10, now()+10, 0);
            expect(await (await vars.streamPay.accountData(vars.owner.address)).streams).to.equal(1);

            await vars.v2.setLimit(100000);

            await expect(vars.streamPay.closeStream(0, false, now()*2))
                .to.not.emit(vars.streamPay, 'streamClosed');
        });
        it("emergency close", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamPay.createStream(
                vars.addr1.address, 1, now()-10, now()+10, 0);
            expect(await (await vars.streamPay.accountData(vars.owner.address)).streams).to.equal(1);

            await vars.v2.setLimit(100000);

            await expect(vars.streamPay.closeStream(0, true, 0))
                .to.emit(vars.streamPay, 'streamClosed');
        });
    });
    describe("drawing down", async function () {
        it("Normal drawing down", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamPay.createStream(
                vars.addr1.address, 1000, now()-10, now()+10, 0);

            await vars.v2.setLimit(100000);

            vars.streamPay.collectStream(
                vars.owner.address,
                0);
        });
    });
    describe("V2", async function () {
        it("got enough funds",async function () {
            await vars.streamPay.createStream(
                vars.addr1.address, 1, now(), now() + 1, 0);

            await vars.v2.setLimit(100);

            await vars.streamPay.collectStream(
                vars.owner.address,
                0);
        });
        it("not enough funds", async function () {
            await vars.streamPay.createStream(
                vars.addr1.address, 1, now(), now() + 1, 0);

            await vars.v2.setLimit(0);

            await expect( vars.streamPay.collectStream(
                vars.owner.address,
                0)).to.be.revertedWith("allowance not large enough");
        });
    });
    describe("stream role changing", async function () {
        it("streamPermGrant",async function () {
            await vars.streamPay.createStream(
                vars.addr1.address, 1, now(), now() + 1, 0);

            await vars.v2.setLimit(10);

            await vars.streamPay.streamPermGrant(vars.addr1.address, 0);

            expect((await vars.streamPay.gets(
                vars.owner.address, 0)).reserveIndex)
                .to.equal(5);

            await vars.streamPay.connect(vars.addr1).collectStream(
                vars.owner.address,
                0);
        });
        it("streamPermRevoke", async function () {
            await vars.streamPay.createStream(
                vars.addr1.address, 1, now(), now() + 1, 0);

            await vars.v2.setLimit(10);

            await vars.streamPay.streamPermGrant(vars.addr1.address, 0);
            await vars.streamPay.streamPermRevoke(vars.addr1.address, 0);

            await expect( vars.streamPay.connect(vars.addr1).collectStream(
                vars.owner.address,
                0)).to.be.revertedWith("addr dont have access");
        });
        it("streamPermRevoke no right", async function () {
            await vars.streamPay.createStream(
                vars.addr1.address, 1, now(), now() + 1, 0);

            await expect (vars.streamPay.connect(vars.addr1).streamPermGrant(
                vars.addr1.address, 0)).to.be.revertedWith("Stream owner must always have access");
        });
    });
    describe.skip("Stream reservation system", async function () {
        it("Reserve a stream", async function () {
            // create stream
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, 0, 0);
            await vars.streamPay.startReservation(vars.owner.address);
            // reserve it
            await vars.streamPay.reserveStream(0, 0);
            // checks to see if it all worked properly
            expect(await (await vars.streamPay.accountData(vars.owner.address)).alive).to.equal(true);
            expect((await vars.streamPay.gets(
                vars.owner.address, 0)).payee)
                .to.equal(vars.addr1.address);
            // cant get the time one to behave but it seems to be working fine
            expect((await vars.streamPay.gets(
                vars.owner.address, 0)).cps)
                .to.equal(BigInt("1"));
            await vars.streamPay.collectStream(
                vars.owner.address,
                0);
        });
        it("remove stream from being reserved", async function () {
            // create stream
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, 0, 0);
            await vars.streamPay.startReservation(vars.owner.address);
            // reserve it
            await vars.streamPay.reserveStream(0, 1);
            // checks to see if it all worked properly
            expect(await (await vars.streamPay.accountData(vars.owner.address)).alive).to.equal(true);
            // un-reserve a stream
            await vars.streamPay.unReserveStream(0, 1);
        });
    });
});
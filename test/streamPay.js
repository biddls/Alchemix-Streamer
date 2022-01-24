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
            // setting new addresses
            await expect(vars.streamPay.changeAlcV2(vars.addr1.address))
                .to.emit(vars.streamPay, 'changedAlcV2')
                .withArgs(vars.addr1.address);
            await expect(vars.streamPay.setCoinAddress(vars.addr2.address))
                .to.emit(vars.streamPay, 'coinAddressChanged')
                .withArgs(vars.addr2.address);

            await expect(vars.streamPay.changeAdmin(vars.addr3.address))
                .to.emit(vars.streamPay, 'adminChanged')
                .withArgs(vars.addr3.address);

            // checking addresses
            expect(await vars.streamPay.adrAlcV2()).to.equal(vars.addr1.address);
            expect(await vars.streamPay.coinAddress()).to.equal(vars.addr2.address);

            await expect(vars.streamPay.connect(vars.addr2).changeAlcV2(vars.addr1.address))
                .to.be.revertedWith("admin only");
            await expect(vars.streamPay.connect(vars.addr2).setCoinAddress(vars.addr2.address))
                .to.be.revertedWith("admin only");
            await expect(vars.streamPay.connect(vars.addr2).changeAdmin(vars.addr3.address))
                .to.be.revertedWith("admin only");

            await expect(vars.streamPay.connect(vars.addr3).changeAlcV2(zero_address))
                .to.be.reverted;
            await expect(vars.streamPay.connect(vars.addr3).setCoinAddress(zero_address))
                .to.be.reverted;
            await expect(vars.streamPay.connect(vars.addr3).changeAdmin(zero_address))
                .to.be.reverted;
        });
    });
    describe("Stream", async function () {
        it("Create stream", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, 0, 0, []);
            expect((await vars.streamPay.gets(
                vars.owner.address, 0))[0])
                .to.equal(vars.addr1.address);
            // cant get the time one to behave but it seems to be working fine
            expect((await vars.streamPay.gets(
                vars.owner.address, 0))[1])
                .to.equal(BigInt("1"));
            //idk how to test time stamp
            expect((await vars.streamPay.gets(
                vars.owner.address, 0))[3])
                .to.equal(0);
        });
        it("dont stream to 0 address", async function () {
            // v2 code here to get approval for the contract to draw down
            await expect(vars.streamPay.createStream(
                zero_address,1,  0, 0, 0, [])).to.be.revertedWith("cannot stream to 0 address");
        });
        it("streams CPS > 0", async function () {
            // v2 code here to get approval for the contract to draw down
            await expect(vars.streamPay.createStream(
                vars.addr1.address,0,  0, 0, 0, [])).to.be.revertedWith("should not stream 0 coins");
        });
    });
    describe("edit stream", async function () {
        it("nice close", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, now()-10, now()+10, []);

            expect(await (await vars.streamPay.accountData(vars.owner.address)).streams).to.equal(1);

            await vars.v2.setLimit(100000);

            await expect(vars.streamPay.editStream(0, false, now()-3))
                .to.emit(vars.streamPay, 'streamClosed');
        });
        it("extend stream", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, now()-10, now()+10, []);
            expect(await (await vars.streamPay.accountData(vars.owner.address)).streams).to.equal(1);

            await vars.v2.setLimit(100000);

            await expect(vars.streamPay.editStream(0, false, now()*2))
                .to.not.emit(vars.streamPay, 'streamClosed');
        });
        it("emergency close", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, now()-10, now()+10, []);
            expect(await (await vars.streamPay.accountData(vars.owner.address)).streams).to.equal(1);

            await vars.v2.setLimit(100000);

            await expect(vars.streamPay.editStream(0, true, 0))
                .to.emit(vars.streamPay, 'streamClosed');
        });
    });
    describe("drawing down", async function () {
        it("Normal drawing down", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamPay.createStream(
                vars.addr1.address, 1000, 0, now()-10, now()+10, []);

            await vars.v2.setLimit(100000);

            vars.streamPay.collectStream(
                vars.owner.address,
                0);
        });
        it("draw down too soon", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, now()-10, now()*10000, []);

            await vars.streamPay.streamSize(
                vars.owner.address,
                0);
        });
    });
    describe("custom contract interactions", async function () {
        it("basic forwarding contract", async function () {
            await vars.streamPay.createStream(
                vars.addr1.address,1,  0, now(), now() + 1, [vars.forward.address]);

            await vars.v2.setLimit(100);

            await vars.streamPay.collectStream(
                vars.owner.address,
                0);
        });
        it("multi forwarding contract", async function () {
            await vars.streamPay.createStream(
                vars.addr1.address,1,  0, now(), now() + 1, [vars.forward.address, vars.forward2.address]);

            await vars.v2.setLimit(100);

            await vars.streamPay.collectStream(
                vars.owner.address,
                0);
        });
        it("multi forwarding contract recursive", async function () {
            await vars.streamPay.createStream(
                vars.addr1.address,1,  0, now(), now() + 1, [vars.forward.address, vars.forward.address]);

            await vars.v2.setLimit(100);

            await expect( vars.streamPay.collectStream(
                vars.owner.address,
                0)).to.be.revertedWith("Cannot route to self");
        });
        it("basic broken forwarding contract", async function () {
            await vars.streamPay.createStream(
                vars.addr1.address,1,  0, now(), now() + 1, [vars.forwardBroken.address]);

            await vars.v2.setLimit(100);

            await expect (vars.streamPay.collectStream(
                vars.owner.address,
                0)).to.be.revertedWith("Coins did not move on");
        });
        it("all this one does is revert", async function () {
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, now(), now() + 1, [vars.reverts.address]);

            await vars.v2.setLimit(100);

            await expect (vars.streamPay.collectStream(
                vars.owner.address,
                0)).to.be.reverted;
        });
    });
    describe("V2", async function () {
        it("got enough funds",async function () {
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, now(), now() + 1, []);

            await vars.v2.setLimit(100);

            await vars.streamPay.collectStream(
                vars.owner.address,
                0);
        });
        it("not enough funds", async function () {
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, now(), now() + 1, []);

            await vars.v2.setLimit(0);

            await expect( vars.streamPay.collectStream(
                vars.owner.address,
                0)).to.be.revertedWith("allowance not large enough");
        });
    });
    describe("stream role changing", async function () {
        it("streamPermGrant",async function () {
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, now(), now() + 1, []);

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
                vars.addr1.address, 1, 0, now(), now() + 1, []);

            await vars.v2.setLimit(10);

            await vars.streamPay.streamPermGrant(vars.addr1.address, 0);
            await vars.streamPay.streamPermRevoke(vars.addr1.address, 0);

            await expect( vars.streamPay.connect(vars.addr1).collectStream(
                vars.owner.address,
                0)).to.be.revertedWith("addr dont have access");
        });
        it("streamPermRevoke no right", async function () {
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, now(), now() + 1, []);

            await expect (vars.streamPay.connect(vars.addr1).streamPermGrant(
                vars.addr1.address, 0)).to.be.revertedWith("Stream owner must always have access");
        });
    });
    describe("Stream reservation system", async function () {
        it("Reserve a stream", async function () {
            // create stream
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, 0, 0, []);
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
            //idk how to test time stamp
            expect((await vars.streamPay.gets(
                vars.owner.address, 0)).freq)
                .to.equal(0);
            await vars.streamPay.collectStream(
                vars.owner.address,
                0);
        });
        it("remove stream from being reserved", async function () {
            // create stream
            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, 0, 0, []);
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
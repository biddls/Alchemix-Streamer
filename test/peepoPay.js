const { expect } = require("chai");
const { testing } = require("../script/testing.js");

const zero_address = "0x0000000000000000000000000000000000000000";


function sleep(milliseconds) {
    const start = Date.now();
    while (Date.now() - start < milliseconds);
}

function now(){
    return Math.floor(+new Date() / 1000);
}

describe("peepoPay", function () {

    let vars;

    beforeEach(async function () {
        vars = await testing();
    });

    describe("Token contract setup", async function () {
        it("Admin tooling tests", async function () {
            // setting new addresses
            await expect(vars.peepoPay.changeAlcV2(vars.addr1.address))
                .to.emit(vars.peepoPay, 'changedAlcV2')
                .withArgs(vars.addr1.address);

            await expect(vars.peepoPay.setCoinAddress(vars.addr2.address))
                .to.emit(vars.peepoPay, 'coinAddressChanged')
                .withArgs(vars.addr2.address);

            await expect(vars.peepoPay.changeAdmin(vars.addr3.address))
                .to.emit(vars.peepoPay, 'adminChanged')
                .withArgs(vars.addr3.address);

            // checking addresses
            expect(await vars.peepoPay.adrAlcV2()).to.equal(vars.addr1.address);
            expect(await vars.peepoPay.coinAddress()).to.equal(vars.addr2.address);

            await expect(vars.peepoPay.connect(vars.addr2).changeAlcV2(vars.addr1.address))
                .to.be.revertedWith("admin only");
            await expect(vars.peepoPay.connect(vars.addr2).setCoinAddress(vars.addr2.address))
                .to.be.revertedWith("admin only");
            await expect(vars.peepoPay.connect(vars.addr2).changeAdmin(vars.addr3.address))
                .to.be.revertedWith("admin only");

            await expect(vars.peepoPay.connect(vars.addr3).changeAlcV2(zero_address))
                .to.be.reverted;
            await expect(vars.peepoPay.connect(vars.addr3).setCoinAddress(zero_address))
                .to.be.reverted;
            await expect(vars.peepoPay.connect(vars.addr3).changeAdmin(zero_address))
                .to.be.reverted;
        });
    });
    describe("Stream", async function () {
        it("Create stream", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.peepoPay.createStream(
                vars.addr1.address, 1, 0, 0, 0, []);
            expect((await vars.peepoPay.gets(
                vars.owner.address, 0))[0])
                .to.equal(vars.addr1.address);
            // cant get the time one to behave but it seems to be working fine
            expect((await vars.peepoPay.gets(
                vars.owner.address, 0))[1])
                .to.equal(BigInt("1"));
            //idk how to test time stamp
            expect((await vars.peepoPay.gets(
                vars.owner.address, 0))[3])
                .to.equal(0);
        });
        it("dont stream to 0 address", async function () {
            // v2 code here to get approval for the contract to draw down
            await expect(vars.peepoPay.createStream(
                zero_address,1,  0, 0, 0, [])).to.be.revertedWith("cannot stream to 0 address");
        });
        it("streams CPS > 0", async function () {
            // v2 code here to get approval for the contract to draw down
            await expect(vars.peepoPay.createStream(
                vars.addr1.address,0,  0, 0, 0, [])).to.be.revertedWith("should not stream 0 coins");
        });
    });
    describe("closing stream", async function () {
        it("Close stream", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.peepoPay.createStream(
                vars.addr1.address,1,  0, 0, 0, []);
            // await vars.v2.setLimit(100);

            expect((await vars.peepoPay.gets(
                vars.owner.address, vars.addr1.address))[1])
                .to.equal(BigInt("0"));
            // cant get the time one to behave but it seems to be working fine
            expect((await vars.peepoPay.gets(
                vars.owner.address, vars.addr1.address))[1])
                .to.equal(BigInt("0"));

            await expect(vars.peepoPay.closeStream(1))
                .to.emit(vars.peepoPay, 'streamClosed');
        });
    });
    describe("drawing down", async function () {
        it("Normal drawing down", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.peepoPay.createStream(
                vars.addr1.address, 1000, 0, now()-10, now()+10, []);

            await vars.v2.setLimit(100000);

            vars.peepoPay.drawDownStream(
                vars.owner.address,
                0);
        });
        it("draw down too soon", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.peepoPay.createStream(
                vars.addr1.address, 1, 0, now()-10, now()*10000, []);

            await vars.peepoPay.streamSize(
                vars.owner.address,
                0);
        });
    });
    describe("custom contract interactions", async function () {
        it("basic forwarding contract", async function () {
            await vars.peepoPay.createStream(
                vars.addr1.address,1,  0, now(), now() + 1, [vars.forward.address]);

            await vars.v2.setLimit(100);

            await vars.peepoPay.drawDownStream(
                vars.owner.address,
                0);
        });
        it("multi forwarding contract", async function () {
            await vars.peepoPay.createStream(
                vars.addr1.address,1,  0, now(), now() + 1, [vars.forward.address, vars.forward2.address]);

            await vars.v2.setLimit(100);

            await vars.peepoPay.drawDownStream(
                vars.owner.address,
                0);
        });
        it("multi forwarding contract recursive", async function () {
            await vars.peepoPay.createStream(
                vars.addr1.address,1,  0, now(), now() + 1, [vars.forward.address, vars.forward.address]);

            await vars.v2.setLimit(100);

            await expect( vars.peepoPay.drawDownStream(
                vars.owner.address,
                0)).to.be.revertedWith("Cannot route to self");
        });
        it("basic broken forwarding contract", async function () {
            await vars.peepoPay.createStream(
                vars.addr1.address,1,  0, now(), now() + 1, [vars.forwardBroken.address]);

            await vars.v2.setLimit(100);

            await expect (vars.peepoPay.drawDownStream(
                vars.owner.address,
                0)).to.be.revertedWith("Coins did not move on");
        });
        it("all this one does is revert", async function () {
            await vars.peepoPay.createStream(
                vars.addr1.address, 1, 0, now(), now() + 1, [vars.reverts.address]);

            await vars.v2.setLimit(100);

            await expect (vars.peepoPay.drawDownStream(
                vars.owner.address,
                0)).to.be.reverted;
        });
    });
    describe("V2", async function () {
        it("got enough funds",async function () {
            await vars.peepoPay.createStream(
                vars.addr1.address, 1, 0, now(), now() + 1, []);

            await vars.v2.setLimit(100);

            await vars.peepoPay.drawDownStream(
                vars.owner.address,
                0);
        });
        it("not enough funds", async function () {
            await vars.peepoPay.createStream(
                vars.addr1.address, 1, 0, now(), now() + 1, []);

            await vars.v2.setLimit(0);

            await expect( vars.peepoPay.drawDownStream(
                vars.owner.address,
                0)).to.be.revertedWith("allowance not large enough");
        });
    });
    describe("stream role changing", async function () {
        it("streamPermGrant",async function () {
            await vars.peepoPay.createStream(
                vars.addr1.address, 1, 0, now(), now() + 1, []);

            await vars.v2.setLimit(10);

            await vars.peepoPay.streamPermGrant(0, vars.addr1.address);

            await vars.peepoPay.connect(vars.addr1).drawDownStream(
                vars.owner.address,
                0);
        });
        it("streamPermRevoke", async function () {
            await vars.peepoPay.createStream(
                vars.addr1.address, 1, 0, now(), now() + 1, []);

            await vars.v2.setLimit(10);

            await vars.peepoPay.streamPermGrant(0, vars.addr1.address);
            await vars.peepoPay.streamPermRevoke(0, vars.addr1.address);

            await expect( vars.peepoPay.connect(vars.addr1).drawDownStream(
                vars.owner.address,
                0)).to.be.revertedWith("addr dont have access");
        });
        it("streamPermRevoke no right", async function () {
            await vars.peepoPay.createStream(
                vars.addr1.address, 1, 0, now(), now() + 1, []);

            await expect (vars.peepoPay.connect(vars.addr1).streamPermGrant(
                0, vars.addr1.address)).to.be.revertedWith("no access allowed");
        });
    });
});
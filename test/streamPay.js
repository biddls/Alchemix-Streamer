const { expect } = require("chai");
const { testing } = require("../script/testing.js");

const zero_address = "0x0000000000000000000000000000000000000000";

describe("streamPay", function () {

    let vars;

    beforeEach(async function () {
        vars = await testing();
    });

    describe("basic checks", async function () {
        it("peepoPay address check", async function () {
            expect(await vars.streamPay.peepoPayCont()).to.equal(vars.peepoPay.address);
        });
    });
    describe("account creation", async function () {
        it("lazyStreamer set up checks", async function () {
            await vars.streamPay.accountCreation();
            expect(await vars.streamPay.accounts(vars.owner.address)).to.not.equal(zero_address);
        });
    });
    describe("basic", async function () {
        it("populating", async function () {
            await vars.streamPay.accountCreation();

            await vars.peepoPay.createStream(
                vars.addr1.address, 1, 0, 0, 0, []);

            await vars.streamPay.populate(1, [0]);
        });
/*        it("lazy draw down", async function () {
            await vars.streamPay.accountCreation();

            await vars.peepoPay.createStream(
                1, vars.addr1.address, 0, 0, 0, []);

            await vars.streamPay.populate(0, [0]);

            await vars.streamPay.lazyDrawdown(vars.owner.address, 0);
        });
        it("lazy draw down recursive", async function () {
            await vars.streamPay.accountCreation();

            await vars.peepoPay.createStream(
                1, vars.addr1.address, 0, 0, 0, []);

            await vars.streamPay.populate(1, [0]);

            await vars.streamPay.lazyDrawdown(vars.owner.address, 0);
        });
        it("lazy draw down to empy day", async function () {
            await vars.streamPay.accountCreation();

            await vars.peepoPay.createStream(
                1, vars.addr1.address, 0, 0, 0, []);

            await vars.streamPay.populate(1, [0]);

            await vars.streamPay.lazyDrawdown(vars.owner.address, 0);
            await vars.streamPay.lazyDrawdown(vars.owner.address, 0);
        });*/
        it("lazy draw down remove day", async function () {
            await vars.streamPay.accountCreation();

            await vars.peepoPay.createStream(
                vars.addr1.address, 1, 0, 0, 0, []);

            await vars.streamPay.populate(1, [0]);

            await vars.streamPay.removeStream(0, 0);
        });
    });
});
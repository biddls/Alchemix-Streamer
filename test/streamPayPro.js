const { expect } = require("chai");
const { testing } = require("../script/testing.js");

const zero_address = "0x0000000000000000000000000000000000000000";

describe("streamPayPro", function () {

    let vars;

    beforeEach(async function () {
        vars = await testing();
    });

    describe("basic checks", async function () {
        it("streamPay address check", async function () {
            expect(await vars.streamPayPro.streamPayCont()).to.equal(vars.streamPay.address);
        });
    });
    describe("account creation", async function () {
        it("lazyStreamer set up checks", async function () {
            await vars.streamPayPro.accountCreation();
            expect(await vars.streamPayPro.accounts(vars.owner.address)).to.not.equal(zero_address);
        });
    });
    describe("basic", async function () {
        it("populating", async function () {
            await vars.streamPayPro.accountCreation();

            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, 0, 0, []);

            await vars.streamPayPro.populate(1, [0]);
        });
/*        it("lazy draw down", async function () {
            await vars.streamPayPro.accountCreation();

            await vars.streamPay.createStream(
                1, vars.addr1.address, 0, 0, 0, []);

            await vars.streamPayPro.populate(0, [0]);

            await vars.streamPayPro.lazyDrawdown(vars.owner.address, 0);
        });
        it("lazy draw down recursive", async function () {
            await vars.streamPayPro.accountCreation();

            await vars.streamPay.createStream(
                1, vars.addr1.address, 0, 0, 0, []);

            await vars.streamPayPro.populate(1, [0]);

            await vars.streamPayPro.lazyDrawdown(vars.owner.address, 0);
        });
        it("lazy draw down to empy day", async function () {
            await vars.streamPayPro.accountCreation();

            await vars.streamPay.createStream(
                1, vars.addr1.address, 0, 0, 0, []);

            await vars.streamPayPro.populate(1, [0]);

            await vars.streamPayPro.lazyDrawdown(vars.owner.address, 0);
            await vars.streamPayPro.lazyDrawdown(vars.owner.address, 0);
        });*/
        it("lazy draw down remove day", async function () {
            await vars.streamPayPro.accountCreation();

            await vars.streamPay.createStream(
                vars.addr1.address, 1, 0, 0, 0, []);

            await vars.streamPayPro.populate(1, [0]);

            await vars.streamPayPro.removeStream(0, 0);
        });
    });
});
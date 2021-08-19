const { expect } = require("chai");
const { testing } = require("../script/testing.js");

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
        })
    });
    describe("Streams", async function () {
        it("Create Streams", async function () {

        })
    })
});
const { expect } = require("chai");
const { testing } = require("../script/testing.js");

const zero_address = "0x0000000000000000000000000000000000000000";


function sleep(milliseconds) {
    const start = Date.now();
    while (Date.now() - start < milliseconds);
}

describe("deployer", function () {

    let vars;

    beforeEach(async function () {
        vars = await testing();
    });

    describe("Token contract setup", async function () {
        it("Deployment checks", async function () {
            expect (await vars.deployer.admin()).to.equal(
                vars.owner.address);
        });
    });
    describe("admin updates", async function () {
        it("change_routerAddr", async function () {
            await vars.deployer.change_routerAddr(
                vars.addr1.address);

            expect (await vars.deployer.routerAddr()).to.equal(
                vars.addr1.address);
        });
        it("change_alUSD", async function () {
            await vars.deployer.change_alUSD(
                vars.addr1.address);

            expect (await vars.deployer.alUSD()).to.equal(
                vars.addr1.address);
        });
        it("change_AMM", async function () {
            await vars.deployer.change_AMM(
                vars.addr1.address);

            expect (await vars.deployer.AMM()).to.equal(
                vars.addr1.address);
        });
        it("change_Tusd", async function () {
            await vars.deployer.change_Tusd(
                vars.addr1.address);

            expect (await vars.deployer.Tusd()).to.equal(
                vars.addr1.address);
        });
        it("change_admin", async function () {
            await vars.deployer.change_admin(
                vars.addr1.address);

            expect (await vars.deployer.admin()).to.equal(
                vars.addr1.address);
        });
    })
});
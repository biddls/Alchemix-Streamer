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
        it("change_alAsset", async function () {
            await vars.deployer.change_alAsset(
                vars.addr1.address);

            expect (await vars.deployer.alAsset()).to.equal(
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
    });
    describe("else paths", async function () {
        it("change_routerAddr", async function () {
            await expect( vars.deployer.change_routerAddr(
                zero_address)).to.be.reverted;

            await expect( vars.deployer.connect(vars.addr2).change_routerAddr(
                vars.addr1.address)).to.be.reverted;
        });
        it("change_alAsset", async function () {
            await expect( vars.deployer.change_alAsset(
                zero_address)).to.be.reverted;

            await expect( vars.deployer.connect(vars.addr2).change_alAsset(
                vars.addr1.address)).to.be.reverted;
        });
        it("change_AMM", async function () {
            await expect( vars.deployer.change_AMM(
                zero_address)).to.be.reverted;

            await expect( vars.deployer.connect(vars.addr2).change_AMM(
                vars.addr1.address)).to.be.reverted;
        });
        it("change_Tusd", async function () {
            await expect( vars.deployer.change_Tusd(
                zero_address)).to.be.reverted;

            await expect( vars.deployer.connect(vars.addr2).change_Tusd(
                vars.addr1.address)).to.be.reverted;
        });
        it("change_admin", async function () {
            await expect( vars.deployer.change_admin(
                zero_address)).to.be.reverted;

            await expect( vars.deployer.connect(vars.addr2).change_admin(
                vars.addr1.address)).to.be.reverted;
        });
    })
});
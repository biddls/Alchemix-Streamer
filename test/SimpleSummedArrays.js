const { expect } = require("chai");
const { testingSimpleSummedArrs } = require("../script/testing.js");

describe("Simple Summed Arrays", function () {

    let vars;

    beforeEach(async function () {
        vars = await testingSimpleSummedArrs(5);
    });

    describe("Token contract setup", async function () {
        it("admin checking", async function () {
            expect( await vars.ssa.admins(0)).to.equal(vars.owner.address);
            expect( await vars.ssa.admins(1)).to.equal(vars.addr1.address);
        });
        it("self des", async function () {
            await vars.ssa.selfDes();
        });
    });
    describe("Writing data", async function () {
        it("Smol sensible", async function () {
            // adding
            await vars.ssa.write(0, 1, 0, 0);
            expect( await vars.ssa.CPSData(0)).to.equal(1);
            // taking away
            await vars.ssa.write(0, 0, 1, 0);
            expect( await vars.ssa.CPSData(0)).to.equal(0);
        });
        it("index limits", async function () {
            await vars.ssa.write(0, 1, 0, 0);
            expect( await vars.ssa.CPSData(0)).to.equal(1);
            await vars.ssa.write(1, 1, 0, 0);
            expect( await vars.ssa.CPSData(1)).to.equal(1);
            await vars.ssa.write(2, 1, 0, 0);
            expect( await vars.ssa.CPSData(2)).to.equal(1);
            await vars.ssa.write(3, 1, 0, 0);
            expect( await vars.ssa.CPSData(3)).to.equal(1);
            await vars.ssa.write(4, 1, 0, 0);
            expect( await vars.ssa.CPSData(4)).to.equal(1);
            await expect( vars.ssa.write(5, 1, 0, 0)).to.be.revertedWith("Index out of bounds");
            await expect( vars.ssa.write(6, 1, 0, 0)).to.be.revertedWith("Index out of bounds");
        });
    });
});
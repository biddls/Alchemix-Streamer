const { expect } = require("chai");
const { testingSimpleSummedArrs } = require("../script/testing.js");
const { now, sleep } = require("./Util");

async function onChainNow(a) {
    return await a.ssa.now();
}

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
            for (let i = 0; i <= 4; i++) {
                await vars.ssa.write(i, i + 1, 0, 0);
                expect(await vars.ssa.CPSData(i)).to.equal(i + 1);
            }
            await expect( vars.ssa.write(5, 1, 0, 0)).to.be.revertedWith("Index out of bounds");
            await expect( vars.ssa.write(6, 1, 0, 0)).to.be.revertedWith("Index out of bounds");
        });
    });
    describe("Getting total reserved calc", async function () {
        it("basic", async function () {
            await vars.ssa.write(0, 1, 0, 0);
            expect (await vars.ssa.sinceLastData(0)).to.equal(await onChainNow(vars));
            await vars.ssa.write(1, 5, 0, 0);
            expect (await onChainNow(vars) - await vars.ssa.sinceLastData(1)).to.be.greaterThanOrEqual(0);
            await vars.ssa.write(2, 25, 0, 0);
            expect (await onChainNow(vars) - await vars.ssa.sinceLastData(2)).to.be.greaterThanOrEqual(0);
            const reserved1 = (await onChainNow(vars) - (await vars.ssa.sinceLastData(0) - 1)) * await vars.ssa.CPSData(0);

            await expect(vars.ssa.calcReserved(0, false)).to.emit(vars.ssa, "calcRes").withArgs(reserved1);
        });
        it("loops bby", async function () {
            await vars.ssa.write(0, 1, 0, 0);
            expect (await vars.ssa.sinceLastData(0)).to.equal(await onChainNow(vars));
            expect( await vars.ssa.CPSData(0)).to.equal(1);
            await vars.ssa.write(1, 5, 0, 0);
            expect (await onChainNow(vars) - await vars.ssa.sinceLastData(1)).to.be.greaterThanOrEqual(0);
            expect( await vars.ssa.CPSData(1)).to.equal(5);
            await vars.ssa.write(2, 25, 0, 0);
            expect (await onChainNow(vars) - await vars.ssa.sinceLastData(2)).to.be.greaterThanOrEqual(0);
            expect( await vars.ssa.CPSData(2)).to.equal(25);
            let total = 0;
            const _nubIndex = 1;
            for(let a = 0; a <= _nubIndex; a++) {
                for (let i = 0; i <= a; i++) {
                    let temp = ((await onChainNow(vars) - await vars.ssa.sinceLastData(i) + 1) * await vars.ssa.CPSData(i));
                    total += temp;
                    // console.log(a, i, temp, total, BigInt(await vars.ssa.sinceLastData(i)), BigInt(await vars.ssa.CPSData(i)));
                }
                expect(await vars.ssa.calcReserved(a, false)).to.emit(vars.ssa, "calcRes").withArgs(total);
            }
        });
    });
});
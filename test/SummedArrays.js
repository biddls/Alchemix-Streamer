const { expect } = require("chai");
const { testingSumedArrs } = require("../script/testing.js");



describe("Summed Arrays testing", function () {

    let vars;

    beforeEach(async function () {
        vars = await testingSumedArrs(5, 2);
    });

    describe("Contract setup", async function () {
        it("Deployment checks", async function () {
            expect( await vars.summedArs.maxSteps()).to.equal(5)
            expect( await vars.summedArs.stepSize()).to.equal(2)
        });
    });
    describe("Testing and reading data", async function() {
        it("Smol start", async function () {
            await vars.summedArs.write(45, 10)
            expect(await vars.summedArs.data(45)).to.equal(10)
            expect(await vars.summedArs.data(46)).to.equal(10)
            expect(await vars.summedArs.data(48)).to.equal(10)
        });
        it("edges", async function () {
            await vars.summedArs.write(0, 10)
            console.log("index   ", "binary", "read", "held Data")
            for(let i=1;i < 50; i++) {
                console.log(
                    i.toString() + "\t",
                    i.toString(2).padStart(6, '0'),
                    BigInt(await vars.summedArs.read(i)).toString().length < 2? BigInt(await vars.summedArs.read(i)).toString() + " ": BigInt(await vars.summedArs.read(i)).toString(),
                    "  " + BigInt(await vars.summedArs.data(i)).toString()
                )
            }
        });
    });
});
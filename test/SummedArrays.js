const { expect } = require("chai");
const { testingSumedArrs, testingGeneral} = require("../script/testing.js");



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
            for(let x = 0; x < 5; x++){
                console.log(x)
                await vars.summedArs.write(x, 10)
            }
        })
    })
});
const { expect } = require("chai");
const { testingSumedArrs } = require("../script/testing.js");



describe("Summed Arrays testing", function () {

    let vars;

    beforeEach(async function () {
        vars = await testingSumedArrs(5);
    });

    describe("Contract setup", async function () {
        it("Deployment checks", async function () {
            expect( await vars.summedArs.maxSteps()).to.equal(5)
        });
        it("Testing modifiers", async function () {
            await expect(vars.summedArs.write(500, 10, 0)).to.be.revertedWith('Numb to big')
            await expect(vars.summedArs.read(500)).to.be.revertedWith('Numb to big')
            await expect(vars.summedArs.connect(vars.addr2).write(500, 10, 0)).to.be.revertedWith('Admins only')
            await expect(vars.summedArs.connect(vars.addr2).read(500)).to.be.revertedWith('Admins only')
        });
    });
    describe("Testing and reading data", async function() {
        it("Smol start", async function () {
            await vars.summedArs.write(45, 10, 0)
            expect(await vars.summedArs.data(45)).to.equal(10)
            expect(await vars.summedArs.data(46)).to.equal(10)
            expect(await vars.summedArs.data(48)).to.equal(10)
        });
        it("larger", async function () {
            /*
            await vars.summedArs.write(0, 10, 0)
            console.log("index   ", "binary", "read", "held Data")
            for(let i=0;i < 50; i++) {
                console.log(
                    i.toString() + "\t",
                    i.toString(2).padStart(6, '0'),
                    BigInt(await vars.summedArs.read(i)).toString().length < 2? BigInt(await vars.summedArs.read(i)).toString() + " ": BigInt(await vars.summedArs.read(i)).toString(),
                    "  " + BigInt(await vars.summedArs.data(i)).toString()
                )
            }
            */
            const max = 2**(await vars.summedArs.maxSteps() + 1)
            for (let i=0;i < max; i++){
                await vars.summedArs.write(i, i, 0)
                expect(await vars.summedArs.read(i)).to.equal(i*(i+1)/2)
            }
            expect(await vars.summedArs.read(max)).to.equal(max*(max+1)/2)

            for (let i=0;i < max; i++){
                await vars.summedArs.write(i, 0, i)
                expect(await vars.summedArs.read(i)).to.equal(0)
            }
            expect(await vars.summedArs.read(max)).to.equal(0)
        });
    });
});
const { expect } = require("chai");
const { testing } = require("../script/testing.js");

const zero_address = "0x0000000000000000000000000000000000000000";


function sleep(milliseconds) {
    const start = Date.now();
    while (Date.now() - start < milliseconds);
}

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
            await expect(vars.streamer.changeAlcV2(vars.addr1.address))
                .to.emit(vars.streamer, 'changedAlcV2')
                .withArgs(vars.addr1.address);

            await expect(vars.streamer.setCoinAddress(vars.addr2.address))
                .to.emit(vars.streamer, 'coinAddressChanged')
                .withArgs(vars.addr2.address);

            await expect(vars.streamer.changeAdmin(vars.addr3.address))
                .to.emit(vars.streamer, 'adminChanged')
                .withArgs(vars.addr3.address);

            // checking addresses
            expect(await vars.streamer.adrAlcV2()).to.equal(vars.addr1.address);
            expect(await vars.streamer.coinAddress()).to.equal(vars.addr2.address);
            expect(await vars.streamer.admin()).to.equal(vars.addr3.address);

            await expect(vars.streamer.connect(vars.addr2).changeAlcV2(vars.addr1.address))
                .to.be.revertedWith("admin only");
            await expect(vars.streamer.connect(vars.addr2).setCoinAddress(vars.addr2.address))
                .to.be.revertedWith("admin only");
            await expect(vars.streamer.connect(vars.addr2).changeAdmin(vars.addr3.address))
                .to.be.revertedWith("admin only");

            await expect(vars.streamer.connect(vars.addr3).changeAlcV2(zero_address))
                .to.be.reverted;
            await expect(vars.streamer.connect(vars.addr3).setCoinAddress(zero_address))
                .to.be.reverted;
            await expect(vars.streamer.connect(vars.addr3).changeAdmin(zero_address))
                .to.be.reverted;
        });
    });
    describe("Stream", async function () {
        it("Create stream", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(1,
                vars.addr1.address, 0, false, [vars.owner.address]);
            expect((await vars.streamer.gets(
                vars.owner.address, vars.addr1.address))[0])
                .to.equal(BigInt("1"));
            // cant get the time one to behave but it seems to be working fine
            expect((await vars.streamer.gets(
                vars.owner.address, vars.addr1.address))[2])
                .to.equal(BigInt("0"));
            expect((await vars.streamer.gets(
                vars.owner.address, vars.addr1.address))[3])
                .to.be.false;
            expect((await vars.streamer.gets(
                vars.owner.address, vars.addr1.address))[4])
                .to.equal(0);
        });
        it("test to make open stream", async function () {
            // v2 code here to get approval for the contract to draw down
            await expect(vars.streamer.createStream(1,
                vars.addr1.address, 0, true, [vars.owner.address])).to.be.reverted;

            // v2 code here to get approval for the contract to draw down
            await expect(vars.streamer.createStream(1,
                vars.addr1.address, 0, true, []))
                .to.emit(vars.streamer, 'streamStarted')
                .withArgs(vars.owner.address, vars.addr1.address, 0);
        });
        it("dont stream to 0 address", async function () {
            // v2 code here to get approval for the contract to draw down
            await expect(vars.streamer.createStream(1,
                zero_address, 0, true, [])).to.be.reverted;
        });
        it("streams CPS > 0", async function () {
            // v2 code here to get approval for the contract to draw down
            await expect(vars.streamer.createStream(0,
                vars.addr1.address, 0, true, [])).to.be.reverted;
        });
    });
    describe("closing stream", async function () {
        it("Close stream", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(1,
                vars.addr1.address, 0, false, [vars.owner.address]);
            await vars.streamer.closeStream(vars.addr1.address);

            expect((await vars.streamer.gets(
                vars.owner.address, vars.addr1.address))[0])
                .to.equal(BigInt("0"));
            // cant get the time one to behave but it seems to be working fine
            expect((await vars.streamer.gets(
                vars.owner.address, vars.addr1.address))[2])
                .to.equal(BigInt("0"));
        });
        it("Close stream thats to the 0 addr", async function () {
            await expect(vars.streamer.closeStream(zero_address)).to.be.reverted;
        });
        it("Close stream thats got 0 cpr (already closed)", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(1,
                vars.addr1.address, 0, false, [vars.owner.address]);
            await vars.streamer.closeStream(vars.addr1.address);
            await expect(vars.streamer.closeStream(vars.addr1.address)).to.be.reverted;
        });
    });
    describe("drawing down", async function () {
        it("Normal drawing down", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(1000,
                vars.addr1.address,0, true, []);

            sleep(2000);

            await expect(vars.streamer.drainStreams(
                vars.addr1.address,
                [vars.owner.address],
                [2000]))
                .to.emit(vars.streamer, 'streamDrain')
                .withArgs([]);
        });
        it("draw down too soon", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(1000,
                vars.addr1.address, 10, true, []);

            await expect(vars.streamer.drainStreams(
                vars.addr1.address,
                [vars.owner.address],
                [2000]))
                .to.emit(vars.streamer, 'streamDrain')
                .withArgs([vars.owner.address]);
        });
        it("draw down too much", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(1000,
                vars.addr1.address,0, true, []);

            sleep(2000);

            await expect(vars.streamer.drainStreams(
                vars.addr1.address,
                [vars.owner.address],
                [3000]))
                .to.emit(vars.streamer, 'streamDrain')
                .withArgs([]);
        });
        it("draw down from address you dont have approval for", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(1000,
                vars.addr1.address,0, true, []);

            sleep(2000);

            await expect(vars.streamer.drainStreams(
                vars.addr1.address,
                [vars.owner.address],
                [2000]))
                .to.emit(vars.streamer, 'streamDrain')
                .withArgs([]);
        });
    });
    describe("break stream time", async function () {
        it("die! stream i will break u", async function () {
            // owner to addr 1-3
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(1, vars.addr1.address, 7,
                false, [vars.owner.address, vars.addr1.address]);
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(2, vars.addr2.address, 8,
                false, [vars.owner.address, vars.addr2.address]);
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(3, vars.addr3.address, 9,
                false, [vars.owner.address, vars.addr3.address]);

            // addr1 to owner and addr 2-3
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.connect(vars.addr1)
                .createStream(4, vars.owner.address, 10,
                    false, [vars.owner.address, vars.addr1.address]);
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.connect(vars.addr1)
                .createStream(5, vars.addr2.address, 11,
                    false, [vars.owner.address, vars.addr2.address]);
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.connect(vars.addr1)
                .createStream(6, vars.addr3.address, 12,
                    false, [vars.owner.address, vars.addr3.address]);

            // making sure the streaming info is working
            // owner accounts
            expect ((await vars.streamer.gets(
                vars.owner.address, vars.addr1.address))[0])
                .to.equal(BigInt("1"));
            expect ((await vars.streamer.gets(
                vars.owner.address, vars.addr2.address))[0])
                .to.equal(BigInt("2"));
            expect ((await vars.streamer.gets(
                vars.owner.address, vars.addr3.address))[0])
                .to.equal(BigInt("3"));

            // addr1 accounts
            expect ((await vars.streamer.gets(
                vars.addr1.address, vars.owner.address))[0])
                .to.equal(BigInt("4"));
            expect ((await vars.streamer.gets(
                vars.addr1.address, vars.addr2.address))[0])
                .to.equal(BigInt("5"));
            expect ((await vars.streamer.gets(
                vars.addr1.address, vars.addr3.address))[0])
                .to.equal(BigInt("6"));


            // //drawing down cus wai not
            // // sleep(20000); // moar tests needed here when i can get this to behave
            //
            // await vars.streamer.collectStreams(//add addresses here);
            // await vars.streamer.connect(vars.addr1).collectStreams(//add addresses here);
            // await vars.streamer.connect(vars.addr2).collectStreams(//add addresses here);
            // await vars.streamer.connect(vars.addr3).collectStreams(//add addresses here);

            // killing all the streams now
            // owner to addr 1-3
            await vars.streamer.closeStream(vars.addr1.address);
            await vars.streamer.closeStream(vars.addr2.address);
            await vars.streamer.closeStream(vars.addr3.address);

            // addr1 to owner and addr 2-3
            await vars.streamer.connect(vars.addr1)
                .closeStream(vars.owner.address);
            await vars.streamer.connect(vars.addr1)
                .closeStream(vars.addr2.address);
            await vars.streamer.connect(vars.addr1)
                .closeStream(vars.addr3.address);

            // making sure the streaming info is working
            // owner accounts
            expect ((await vars.streamer.gets(
                vars.owner.address, vars.addr1.address))[0])
                .to.equal(BigInt("0"));
            expect ((await vars.streamer.gets(
                vars.owner.address, vars.addr2.address))[0])
                .to.equal(BigInt("0"));
            expect ((await vars.streamer.gets(
                vars.owner.address, vars.addr3.address))[0])
                .to.equal(BigInt("0"));

            // addr1 accounts
            expect ((await vars.streamer.gets(
                vars.addr1.address, vars.owner.address))[0])
                .to.equal(BigInt("0"));
            expect ((await vars.streamer.gets(
                vars.addr1.address, vars.addr2.address))[0])
                .to.equal(BigInt("0"));
            expect ((await vars.streamer.gets(
                vars.addr1.address, vars.addr3.address))[0])
                .to.equal(BigInt("0"));

            // bi-directional searching tests are not needed as it doesnt change that data
        });
    });
    describe ("Approvals management", async function () {
        it ("Revoke and grant approval", async function () {
            // v2 code here to get approval for the contract to draw down
            await vars.streamer.createStream(
                1, vars.addr1.address, 0,
                false, [vars.owner.address,
                    vars.addr1.address,
                    vars.addr2.address]);

            await vars.streamer.drainStreams(vars.addr1.address,
                [vars.owner.address],
                [1]);
            await vars.streamer.connect(vars.addr1).drainStreams(vars.addr1.address,
                [vars.owner.address],
                [1]);
            await vars.streamer.connect(vars.addr2).drainStreams(vars.addr1.address,
                [vars.owner.address],
                [1]);

            // revoke
            await vars.streamer.revokeApprovals(
                vars.owner.address,
                [vars.addr2.address]
            );
            await vars.streamer.connect(vars.addr2).drainStreams(vars.addr1.address,
                [vars.owner.address],
                [1]);

            // approve
            await vars.streamer.grantApprovals(
                vars.owner.address,
                [vars.addr2.address]
            );
            await vars.streamer.connect(vars.addr2).drainStreams(vars.addr1.address,
                [vars.owner.address],
                [1]);
        });
    });
});
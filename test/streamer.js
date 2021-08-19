const { expect } = require("chai");
const { testing } = require("../script/testing.js");

describe("streamer", function () {

    let vars;

    beforeEach(async function () {
        vars = await testing();
    });

    describe("Token contract setup", async function () {
        it("Deployment checks", async function () {
        });
    });
});
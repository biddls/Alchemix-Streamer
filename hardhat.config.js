require("@nomiclabs/hardhat-waffle");
require('solidity-coverage')
require("hardhat-gas-reporter");
require('hardhat-spdx-license-identifier');

module.exports = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  spdxLicenseIdentifier: {
    overwrite: true,
    runOnCompile: true,
  },
  gasReporter: {//comment me out to toggle
    enabled: process.env.REPORT_GAS
  }
  // npx hardhat coverage
};
const { assert, expect } = require("chai");
const { network, deployments, ethers } = require("hardhat");
const { deploy, log } = deployments;

describe("CringeToken", () => {
  let deployer;
  const initialSupply = 100;
  let CringeToken;
  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    deployer = accounts[0];
    const cringeToken = await ethers.getContractFactory("CringeToken");
    CringeToken = await cringeToken.deploy(initialSupply);
  });
  describe("constructor", async function () {
    it("sets initialSupply and inital money owner correctly", async () => {
      assert.equal(
        await CringeToken.balanceOf(deployer.getAddress()),
        initialSupply
      );
    });
  });
});

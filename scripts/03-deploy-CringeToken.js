const { verify } = require("../utils/verify");
const { ethers, run, network } = require("hardhat");
const deployCringeToken = async () => {
  const { log } = deployments;

  log("Deploying CringeToken and waiting for confirmations...");
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);

  const cringeToken = await ethers.getContractFactory("CringeToken");
  const CringeToken = await cringeToken.deploy(1000);

  console.log("CringeToken: " + CringeToken.address);

  if (network.config.chainId != 31337 && process.env.ETHERSCAN_API_KEY) {
    log("verified");
    await verify(CringeToken.address, [1000]);
  }
  return CringeToken;
};

module.exports = { deployCringeToken };

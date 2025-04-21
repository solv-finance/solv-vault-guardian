const { ethers } = require("hardhat");

const getSigner = async (address) => {
  const signers = await hre.ethers.getSigners();
  return signers.find((signer) => signer.address === address);
};

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const signer = await getSigner(deployer);

  const safeGovernor = "0x312846e1049963969990EF7dbB5e5f7a37c4Ac6C";
  const openFundMarket = "0x6c8dA184B019E6C4Baa710113c0d9DE68A693B1f";

  const FoFNavManagerAuthorizationFactory = await ethers.getContractFactory("FoFNavManagerAuthorization", signer);
  const fofNavManagerAuthorizationAddress = (await deployments.get("rootstock-solvBTC-FoFNavManagerAuthorization")).address;
  const fofNavManagerAuthorization = FoFNavManagerAuthorizationFactory.attach(fofNavManagerAuthorizationAddress);

  const guardianFactory = await ethers.getContractFactory("SolvVaultGuardianForSafe13", signer);
  const guardianAddress = (await deployments.get("rootstock-solvBTC-NavManagerGuardianForSafe13")).address;
  const guardian = guardianFactory.attach(guardianAddress);

  await guardian.setAuthorization(openFundMarket, fofNavManagerAuthorizationAddress);
  console.log(`set authorization ${fofNavManagerAuthorizationAddress} for contract ${openFundMarket}`);

  await guardian.transferGovernance(safeGovernor);
  console.log(`Guardian governor transferred to ${safeGovernor}`);

  await fofNavManagerAuthorization.transferGovernance(safeGovernor);
  console.log(`FoFNavManagerAuthorization governor transferred to ${safeGovernor}`);
};

module.exports.tags = ["rootstock-solvBTC-NavManagerGuardianForSafe13-config"];

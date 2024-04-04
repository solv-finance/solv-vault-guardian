const { ethers } = require("hardhat");

const getSigner = async (address) => {
  const signers = await hre.ethers.getSigners();
  return signers.find((signer) => signer.address === address);
};

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const signer = await getSigner(deployer);
  const BTCB = "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c";

  const safeGovernor = "0x2918067184e8FDbd5CBafB6fBDF16C94A820B9b2";
  const guardianAddress = (await deployments.get("bsc-solvBTC-SolvVaultGuardianForSafe13")).address;

  const openEndFundShare = "0x744697899058b32d84506AD05DC1f3266603aB8A";
  const openEndFundRedemption = "0xAa295fF24c1130A4ceb07842860a8fD7CB9de9Cd";
  const openEndFundAuthorizationAddress = (await deployments.get("bsc-solvBTC-SolvOpenEndFundAuthorization")).address;

  const erc20AuthorizationAddress = (await deployments.get("bsc-solvBTC-ERC20Authorization")).address;

  const guardianFactory = await ethers.getContractFactory("SolvVaultGuardianForSafe13", signer);
  const guardian = guardianFactory.attach(guardianAddress);

  await guardian.setAuthorization(BTCB, erc20AuthorizationAddress);
  console.log(`set authorization ${erc20AuthorizationAddress} for contract ${BTCB}`);

  await guardian.setAuthorization(openEndFundShare, openEndFundAuthorizationAddress);
  console.log(`set authorization ${openEndFundAuthorizationAddress} for contract ${openEndFundShare}`);

  await guardian.setAuthorization(openEndFundRedemption, openEndFundAuthorizationAddress);
  console.log(`set authorization ${openEndFundAuthorizationAddress} for contract ${openEndFundRedemption}`);

  await guardian.transferGovernance(safeGovernor);
  console.log("set authorizations success");
};

module.exports.tags = ["bsc-solvBTC-set-SolvVaultGuardianForSafe13"];

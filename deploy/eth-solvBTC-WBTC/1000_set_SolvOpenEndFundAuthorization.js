const { ethers } = require("hardhat");

const getSigner = async (address) => {
  const signers = await hre.ethers.getSigners();
  return signers.find((signer) => signer.address === address);
};

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const signer = await getSigner(deployer);

  const guardianConfig = require('./00_export_VaultGuardianConfig');

  const WBTC = guardianConfig.ERC20;
  const share = guardianConfig.ShareSFT;
  const redemption = guardianConfig.RedemptionSFT;
  
  const erc20AuthorizationAddress = (await deployments.get("eth-solvBTC-WBTC-ERC20Authorization")).address;
  const openEndFundAuthorizationAddress = (await deployments.get("eth-solvBTC-WBTC-SolvOpenEndFundAuthorization")).address;
  const guardianAddress = (await deployments.get("eth-solvBTC-WBTC-SolvVaultGuardianForSafe13")).address;

  const guardianFactory = await ethers.getContractFactory("SolvVaultGuardianForSafe13", signer);
  const guardian = guardianFactory.attach(guardianAddress);

  await guardian.setAuthorization(WBTC, erc20AuthorizationAddress);
  console.log(`set authorization ${erc20AuthorizationAddress} for contract ${WBTC}`);

  await guardian.setAuthorization(share, openEndFundAuthorizationAddress);
  console.log(`set authorization ${openEndFundAuthorizationAddress} for contract ${share}`);

  await guardian.setAuthorization(redemption, openEndFundAuthorizationAddress);
  console.log(`set authorization ${openEndFundAuthorizationAddress} for contract ${redemption}`);

  await guardian.transferGovernance(guardianConfig.GuardianGovernor);
  console.log(`Transfer guardian governance to ${guardianConfig.GuardianGovernor}`);
};

module.exports.tags = ["eth-solvBTC-WBTC-set-SolvVaultGuardianForSafe13"];

const { ethers } = require("hardhat");

const getSigner = async (address) => {
  const signers = await hre.ethers.getSigners();
  return signers.find((signer) => signer.address === address);
};

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const signer = await getSigner(deployer);
  const cbBTC = "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf";

  const safeGovernor = "0x312846e1049963969990EF7dbB5e5f7a37c4Ac6C";
  const guardianAddress = (await deployments.get("eth-solvBTC-cbBTC-SolvVaultGuardianForSafe13")).address;

  const openEndFundShare = "0x7d6C3860B71CF82e2e1E8d5D104CF77f5B84f93a";
  const openEndFundRedemption = "0xD3BA838B3e32654aD2Ad1741d2483d807c49e6F9";
  const openEndFundAuthorizationAddress = (await deployments.get("eth-solvBTC-cbBTC-SolvOpenEndFundAuthorization")).address;

  const erc20AuthorizationAddress = (await deployments.get("eth-solvBTC-cbBTC-ERC20Authorization")).address;

  const guardianFactory = await ethers.getContractFactory("SolvVaultGuardianForSafe13", signer);
  const guardian = guardianFactory.attach(guardianAddress);

  await guardian.setAuthorization(cbBTC, erc20AuthorizationAddress);
  console.log(`set authorization ${erc20AuthorizationAddress} for contract ${cbBTC}`);

  await guardian.setAuthorization(openEndFundShare, openEndFundAuthorizationAddress);
  console.log(`set authorization ${openEndFundAuthorizationAddress} for contract ${openEndFundShare}`);

  await guardian.setAuthorization(openEndFundRedemption, openEndFundAuthorizationAddress);
  console.log(`set authorization ${openEndFundAuthorizationAddress} for contract ${openEndFundRedemption}`);

  await guardian.transferGovernance(safeGovernor);
  console.log("set authorizations success");
};

module.exports.tags = ["eth-solvBTC-cbBTC-set-SolvVaultGuardianForSafe13"];

const { ethers } = require("hardhat");

const getSigner = async (address) => {
  const signers = await hre.ethers.getSigners();
  return signers.find((signer) => signer.address === address);
};

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const signer = await getSigner(deployer);

  const safeGovernor = "0xfFB6FCEac2F8fCF650Db346059e8325c282b8C1C";

  const WBTC = "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f";
  const erc20AuthorizationAddress = (await deployments.get("arb-solvBTC-ERC20Authorization")).address;

  const openEndFundShare = "0xD20078BD38AbC1378cB0a3F6F0B359c4d8a7b90E";
  const openEndFundRedemption = "0x5d931F572df1cd730F1ADf3F9Eb5B218D2cE641f";
  const openEndFundAuthorizationAddress = (await deployments.get("arb-solvBTC-SolvOpenEndFundAuthorization")).address;

  const guardianFactory = await ethers.getContractFactory("SolvVaultGuardianForSafe13", signer);
  const guardianAddress = (await deployments.get("arb-solvBTC-SolvVaultGuardianForSafe13")).address;
  const guardian = guardianFactory.attach(guardianAddress);

  await guardian.setAuthorization(WBTC, erc20AuthorizationAddress);
  console.log(`set authorization ${erc20AuthorizationAddress} for contract ${WBTC}`);

  await guardian.setAuthorization(openEndFundShare, openEndFundAuthorizationAddress);
  console.log(`set authorization ${openEndFundAuthorizationAddress} for contract ${openEndFundShare}`);

  await guardian.setAuthorization(openEndFundRedemption, openEndFundAuthorizationAddress);
  console.log(`set authorization ${openEndFundAuthorizationAddress} for contract ${openEndFundRedemption}`);

  await guardian.transferGovernance(safeGovernor);
  console.log("transfer governance success");
};

module.exports.tags = ["arb-solvBTC-set-SolvVaultGuardianForSafe13"];

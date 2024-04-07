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

  const solvFundOfFundShare = "0xD20078BD38AbC1378cB0a3F6F0B359c4d8a7b90E";
  const solvFundOfFundRedemption = "0x5d931F572df1cd730F1ADf3F9Eb5B218D2cE641f";
  const solvFundOfFundSftAuthorizationAddress = (await deployments.get("arb-solvBTC-SolvFundOfFundSftAuthorization")).address;

  const openEndFundShare = "0x22799DAA45209338B7f938edf251bdfD1E6dCB32";
  const openEndFundAuthorizationShareAddress = (await deployments.get("arb-solvBTC-SolvOpenEndFundShareAuthorization")).address;

  const openEndFundRedemption = "0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c";
  const openEndFundAuthorizationRedemptionAddress = (await deployments.get("arb-solvBTC-SolvOpenEndFundRedemptionAuthorization")).address;

  const openEndFundMarket = "0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8";
  const solvOpenEndFundMarketAuthorization = (await deployments.get("arb-solvBTC-SolvOpenEndFundMarketAuthorization")).address;

  const guardianFactory = await ethers.getContractFactory("SolvVaultGuardianForSafe13", signer);
  const guardianAddress = (await deployments.get("arb-solvBTC-SolvVaultGuardianForSafe13")).address;
  const guardian = guardianFactory.attach(guardianAddress);

  await guardian.setAuthorization(WBTC, erc20AuthorizationAddress);
  console.log(`set authorization ${erc20AuthorizationAddress} for contract ${WBTC}`);

  await guardian.setAuthorization(solvFundOfFundShare, solvFundOfFundSftAuthorizationAddress);
  console.log(`set authorization ${solvFundOfFundSftAuthorizationAddress} for contract ${solvFundOfFundShare}`);

  await guardian.setAuthorization(solvFundOfFundRedemption, solvFundOfFundSftAuthorizationAddress);
  console.log(`set authorization ${solvFundOfFundSftAuthorizationAddress} for contract ${solvFundOfFundRedemption}`);

  await guardian.setAuthorization(openEndFundShare, openEndFundAuthorizationRedemptionAddress);
  console.log(`set authorization ${openEndFundAuthorizationRedemptionAddress} for contract ${openEndFundShare}`);

  await guardian.setAuthorization(openEndFundRedemption, solvOpenEndFundMarketAuthorization);
  console.log(`set authorization ${solvOpenEndFundMarketAuthorization} for contract ${openEndFundRedemption}`);

  await guardian.setAuthorization(openEndFundMarket, solvOpenEndFundMarketAuthorization);
  console.log(`set authorization ${solvOpenEndFundMarketAuthorization} for contract ${openEndFundMarket}`);

  await guardian.transferGovernance(safeGovernor);
  console.log("set authorizations success");
};

module.exports.tags = ["arb-solvBTC-set-SolvVaultGuardianForSafe13"];

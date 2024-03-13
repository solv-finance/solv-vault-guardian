const { ethers } = require("hardhat");

const getSigner = async (address) => {
  const signers = await hre.ethers.getSigners();
  return signers.find((signer) => signer.address === address);
};

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const signer = await getSigner(deployer);

  const safeGovernor = "0x54332697767D6ee1f0f0A2562ED459771B8916ce";
  const guardianAddress = (await deployments.get("arb-pilot-SolvVaultGuardianForSafe13")).address;

  const USDT = "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9";
  const erc20AuthorizationAddress = (await deployments.get("arb-pilot-ERC20Authorization")).address;

  const openEndFundShare = "0x22799DAA45209338B7f938edf251bdfD1E6dCB32";
  const openEndFundRedemption = "0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c";
  const openEndFundAuthorizationAddress = (await deployments.get("arb-pilot-SolvOpenEndFundAuthorization")).address;

  const guardianFactory = await ethers.getContractFactory("SolvVaultGuardianForSafe13", signer);
  const guardian = guardianFactory.attach(guardianAddress);

  await guardian.setAuthorization(USDT, erc20AuthorizationAddress);
  console.log(`set authorization ${erc20AuthorizationAddress} for contract ${USDT}`);

  await guardian.setAuthorization(openEndFundShare, openEndFundAuthorizationAddress);
  console.log(`set authorization ${openEndFundAuthorizationAddress} for contract ${openEndFundShare}`);
  
  await guardian.setAuthorization(openEndFundRedemption, openEndFundAuthorizationAddress);
  console.log(`set authorization ${openEndFundAuthorizationAddress} for contract ${openEndFundRedemption}`);

  await guardian.transferGovernance(safeGovernor);
  console.log("set authorizations success");
};

module.exports.tags = ["arb-pilot-set-SolvVaultGuardianForSafe13"];

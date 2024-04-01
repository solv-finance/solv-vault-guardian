const { ethers } = require("hardhat");

const getSigner = async (address) => {
  const signers = await hre.ethers.getSigners();
  return signers.find((signer) => signer.address === address);
};

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const signer = await getSigner(deployer);

  const safeGovernor = "";
  const guardianAddress = (
    await deployments.get("merlin-solvBTCTest-SolvVaultGuardianForSafe13")
  ).address;

  const openEndFundShare = "";
  const openEndFundRedemption = "";
  const openEndFundAuthorizationAddress = (
    await deployments.get("merlin-solvBTCTest-SolvOpenEndFundAuthorization")
  ).address;

  const guardianFactory = await ethers.getContractFactory(
    "SolvVaultGuardianForSafe13",
    signer
  );
  const guardian = guardianFactory.attach(guardianAddress);

  await guardian.setAuthorization(USDT, erc20AuthorizationAddress);
  console.log(
    `set authorization ${erc20AuthorizationAddress} for contract ${USDT}`
  );

  await guardian.setAuthorization(
    openEndFundShare,
    openEndFundAuthorizationAddress
  );
  console.log(
    `set authorization ${openEndFundAuthorizationAddress} for contract ${openEndFundShare}`
  );

  await guardian.setAuthorization(
    openEndFundRedemption,
    openEndFundAuthorizationAddress
  );
  console.log(
    `set authorization ${openEndFundAuthorizationAddress} for contract ${openEndFundRedemption}`
  );

  await guardian.transferGovernance(safeGovernor);
  console.log("set authorizations success");
};

module.exports.tags = ["merlin-solvBTCTest-set-SolvVaultGuardianForSafe13"];

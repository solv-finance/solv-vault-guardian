const { ethers } = require("hardhat");

const getSigner = async (address) => {
  const signers = await hre.ethers.getSigners();
  return signers.find((signer) => signer.address === address);
};

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const signer = await getSigner(deployer);
  const BTCB = "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c";

  const safeGovernor = "0x312846e1049963969990EF7dbB5e5f7a37c4Ac6C";
  const guardianAddress = (
    await deployments.get("bsc-solvBTC-Ethena-SolvVaultGuardianForSafe13")
  ).address;

  const openEndFundShare = "0xb816018e5d421e8b809a4dc01af179d86056ebdf";
  const openEndFundRedemption = "0xe16cec2f385ea7a382772334a44506a865f98562";
  const openEndFundAuthorizationAddress = (
    await deployments.get("bsc-solvBTC-Ethena-SolvOpenEndFundAuthorization")
  ).address;

  const erc20AuthorizationAddress = (
    await deployments.get("bsc-solvBTC-Ethena-ERC20Authorization")
  ).address;

  const guardianFactory = await ethers.getContractFactory(
    "SolvVaultGuardianForSafe13",
    signer
  );
  const guardian = guardianFactory.attach(guardianAddress);

  await guardian.setAuthorization(BTCB, erc20AuthorizationAddress);
  console.log(
    `set authorization ${erc20AuthorizationAddress} for contract ${BTCB}`
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

module.exports.tags = ["bsc-solvBTC-Ethena-set-SolvVaultGuardianForSafe13"];

const { ethers } = require("hardhat");

const getSigner = async (address) => {
  const signers = await hre.ethers.getSigners();
  return signers.find((signer) => signer.address === address);
};

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const signer = await getSigner(deployer);
  const mBTC = "0xB880fd278198bd590252621d4CD071b1842E9Bcd";

  const safeGovernor = "0xE8E7764EDe76bB7306C21BaD07D6da2c30B81b8F";
  const guardianAddress = (
    await deployments.get("merlin-solvBTCTest-SolvVaultGuardianForSafe13")
  ).address;

  const openEndFundShare = "0x1f4d23513c3ef0d63b97bbd2ce7c845ebb1cf1ce";
  const openEndFundRedemption = "0x9d7795c2bd2ef6098c74cb0865691cbf6aa40887";
  const openEndFundAuthorizationAddress = (
    await deployments.get("merlin-solvBTCTest-SolvOpenEndFundAuthorization")
  ).address;

  const erc20AuthorizationAddress = (
    await deployments.get("merlin-solvBTCTest-ERC20Authorization")
  ).address;

  const guardianFactory = await ethers.getContractFactory(
    "SolvVaultGuardianForSafe13",
    signer
  );
  const guardian = guardianFactory.attach(guardianAddress);

  await guardian.setAuthorization(mBTC, erc20AuthorizationAddress, {
    gasPrice: 0.05e9,
  });
  console.log(
    `set authorization ${erc20AuthorizationAddress} for contract ${mBTC}`
  );

  await guardian.setAuthorization(
    openEndFundShare,
    openEndFundAuthorizationAddress,
    {
      gasPrice: 0.05e9,
    }
  );
  console.log(
    `set authorization ${openEndFundAuthorizationAddress} for contract ${openEndFundShare}`
  );

  await guardian.setAuthorization(
    openEndFundRedemption,
    openEndFundAuthorizationAddress,
    {
      gasPrice: 0.05e9,
    }
  );
  console.log(
    `set authorization ${openEndFundAuthorizationAddress} for contract ${openEndFundRedemption}`
  );

  await guardian.transferGovernance(safeGovernor, {
    gasPrice: 0.05e9,
  });
  console.log("set authorizations success");
};

module.exports.tags = ["merlin-solvBTCTest-set-SolvVaultGuardianForSafe13"];

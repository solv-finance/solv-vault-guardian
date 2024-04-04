const { ethers } = require("hardhat");

const getSigner = async (address) => {
  const signers = await hre.ethers.getSigners();
  return signers.find((signer) => signer.address === address);
};

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const signer = await getSigner(deployer);
  const mBTC = "0xB880fd278198bd590252621d4CD071b1842E9Bcd";

  const safeGovernor = "0x89d9935a5103e48ACe3aAC3448DB249FFC42230F";
  const guardianAddress = (await deployments.get("merlin-solvBTC-SolvVaultGuardianForSafe13")).address;

  const openEndFundShare = "0x1f4d23513c3ef0d63b97bbd2ce7c845ebb1cf1ce";
  const openEndFundRedemption = "0x9d7795c2bd2ef6098c74cb0865691cbf6aa40887";
  const openEndFundAuthorizationAddress = (await deployments.get("merlin-solvBTC-SolvOpenEndFundAuthorization")).address;

  const erc20AuthorizationAddress = (await deployments.get("merlin-solvBTC-ERC20Authorization")).address;

  const guardianFactory = await ethers.getContractFactory("SolvVaultGuardianForSafe13", signer);
  const guardian = guardianFactory.attach(guardianAddress);

  await guardian.setAuthorization(mBTC, erc20AuthorizationAddress, { gasPrice: 0.05e9 });
  console.log(`set authorization ${erc20AuthorizationAddress} for contract ${mBTC}`);

  await guardian.setAuthorization(
    openEndFundShare,
    openEndFundAuthorizationAddress,
    { gasPrice: 0.05e9 }
  );
  console.log(`set authorization ${openEndFundAuthorizationAddress} for contract ${openEndFundShare}`);

  await guardian.setAuthorization(
    openEndFundRedemption,
    openEndFundAuthorizationAddress,
    { gasPrice: 0.05e9 }
  );
  console.log(`set authorization ${openEndFundAuthorizationAddress} for contract ${openEndFundRedemption}`);

  await guardian.transferGovernance(safeGovernor, { gasPrice: 0.05e9 });
  console.log("set authorizations success");
};

module.exports.tags = ["merlin-solvBTC-set-SolvVaultGuardianForSafe13"];

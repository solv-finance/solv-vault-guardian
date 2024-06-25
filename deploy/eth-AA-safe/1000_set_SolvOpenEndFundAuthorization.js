const { ethers } = require("hardhat");

const getSigner = async (address) => {
  const signers = await hre.ethers.getSigners();
  return signers.find((signer) => signer.address === address);
};

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const signer = await getSigner(deployer);
  const USDT = "0xdac17f958d2ee523a2206206994597c13d831ec7";
  const USDE = "0x4c9EDD5852cd905f086C759E8383e09bff1E68B3";

  const safeGovernor = "0x312846e1049963969990EF7dbB5e5f7a37c4Ac6C";
  const guardianAddress = (
    await deployments.get("eth-AA-Safe-SolvVaultGuardianForSafe13")
  ).address;

  const erc20AuthorizationAddress = (
    await deployments.get("eth-AA-Safe-ERC20Authorization")
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
  await guardian.setAuthorization(USDE, erc20AuthorizationAddress);
  console.log(
    `set authorization ${erc20AuthorizationAddress} for contract ${USDE}`
  );

  const erc20AuthorizationFactory = await ethers.getContractFactory(
    "ERC20Authorization",
    signer
  );
  const erc20Authorization = erc20AuthorizationFactory.attach(
    erc20AuthorizationAddress
  );
  await erc20Authorization.transferGovernance(safeGovernor);

  await guardian.transferGovernance(safeGovernor);
  console.log("set authorizations success");
};

module.exports.tags = ["eth-AA-Safe-set-SolvVaultGuardianForSafe13"];

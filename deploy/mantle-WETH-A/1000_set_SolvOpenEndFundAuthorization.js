const { ethers } = require("hardhat");

const getSigner = async (address) => {
  const signers = await hre.ethers.getSigners();
  return signers.find((signer) => signer.address === address);
};

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();

  const safeGovernor = "0xA53e62dfCAcd3c2CC92eA94D87B2A5F2b3f6fa50";

  const guardianDeployment = await deployments.get("mantle-WETH-A-SolvVaultGuardianForSafe13");
  const erc20ApproveAuthorizationDeployment = await deployments.get("mantle-WETH-A-ERC20ApproveAuthorization");
  const agniAuthorizationDeployment = await deployments.get("mantle-WETH-A-AgniAuthorization");
  const lendleAuthorizationDeployment = await deployments.get("mantle-WETH-A-LendleAuthorization");
  const openEndFundAuthorizationDeployment = await deployments.get("mantle-WETH-A-SolvOpenEndFundAuthorization");

  const signer = await getSigner(deployer);

  const guardianFactory = await ethers.getContractFactory("SolvVaultGuardianForSafe13", signer);
  const guardian = guardianFactory.attach(guardianDeployment.address);

  await guardian.addAuthorizations([
    [
      "ERC20ApproveAuthorization",
      erc20ApproveAuthorizationDeployment.address,
      true,
    ],
    [
      "AgniAuthorization",
      agniAuthorizationDeployment.address,
      true,
    ],
    [
      "LendleAuthorization",
      lendleAuthorizationDeployment.address,
      true,
    ],
    [
      "SolvOpenEndFundAuthorization",
      openEndFundAuthorizationDeployment.address,
      true,
    ],
  ]);

  await guardian.transferGovernance(safeGovernor);
  console.log("set authorizations success");
};

module.exports.tags = ["mantle-WETH-A-set-SolvVaultGuardianForSafe13"];

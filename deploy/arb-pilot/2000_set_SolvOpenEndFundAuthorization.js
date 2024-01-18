const { ethers } = require("hardhat");

const getSigner = async (address) => {
  const signers = await hre.ethers.getSigners();
  return signers.find((signer) => signer.address === address);
};

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();

  const safeGovernor = "0x54332697767D6ee1f0f0A2562ED459771B8916ce";

  const guardianDeployment = await deployments.get(
    "arb-pilot-SolvVaultGuardianForSafe13"
  );
  const erc20TransferAuthorizationDeployment = await deployments.get(
    "arb-pilot-ERC20TransferAuthorization"
  );
  const erc20ApproveAuthorizationDeployment = await deployments.get(
    "arb-pilot-ERC20ApproveAuthorization"
  );
  const openEndFundAuthorizationDeployment = await deployments.get(
    "arb-pilot-SolvOpenEndFundAuthorization"
  );

  const signer = await getSigner(deployer);

  const guardianFactory = await ethers.getContractFactory(
    "SolvVaultGuardianForSafe13",
    signer
  );
  const guardian = await guardianFactory.attach(guardianDeployment.address);

  await guardian.addAuthorizations([
    [
      "SolvOpenEndFundAuthorization",
      openEndFundAuthorizationDeployment.address,
      true,
    ],
    [
      "ERC20TransferAuthorization",
      erc20TransferAuthorizationDeployment.address,
      true,
    ],
    [
      "ERC20ApproveAuthorization",
      erc20ApproveAuthorizationDeployment.address,
      true,
    ],
  ]);

  await guardian.transferGovernance(safeGovernor);
  console.log("set authorizations success");
};

module.exports.tags = ["arb-pilot-set-SolvVaultGuardianForSafe13"];

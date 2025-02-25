const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const guardianConfig = require('./00_export_VaultGuardianConfig');

  const caller = (await deployments.get("eth-solvBTC-tBTC-SolvVaultGuardianForSafe13")).address;

  const spenders = [
    [
      guardianConfig.ERC20, // tBTC
      [
        guardianConfig.ShareSFT,
        guardianConfig.RedemptionSFT
      ],
    ],
  ];

  const receivers = [];

  const deployName = "eth-solvBTC-tBTC-ERC20Authorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "ERC20Authorization",
    args: [caller, spenders, receivers],
    skipIfAlreadyDeployed: true,
    log: true,
  });

  const AuthorizationFactory = await ethers.getContractFactory("ERC20Authorization");
  const authorizationInstance = AuthorizationFactory.attach(authorization.address);
  const currentGovernor = await authorizationInstance.governor();
  const pendingGovernor = await authorizationInstance.pendingGovernor();
  if (currentGovernor != guardianConfig.GuardianGovernor && pendingGovernor != guardianConfig.GuardianGovernor) {
    const transferGovernanceTx = await authorizationInstance.transferGovernance(guardianConfig.GuardianGovernor);
    await transferGovernanceTx.wait();
    console.log(`Governance transferred to ${guardianConfig.GuardianGovernor}`);
  }
};

module.exports.tags = ["eth-solvBTC-tBTC-ERC20Authorization"];

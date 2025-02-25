module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const guardianConfig = require('./00_export_VaultGuardianConfig');
  const safeGovernor = deployer; // will transfer to safeGovernor after deployed
  const allowSetGuard = true;

  const deployName = "eth-solvBTC-WBTC-SolvVaultGuardianForSafe13";
  const guardian = await deploy(deployName, {
    from: deployer,
    contract: "SolvVaultGuardianForSafe13",
    args: [ guardianConfig.Vault, guardianConfig.SafeMultiSendContract, safeGovernor, allowSetGuard],
    skipIfAlreadyDeployed: true,
    log: true
  });
  console.log(`${deployName} deployed at ${guardian.address}`);
};

module.exports.tags = ["eth-solvBTC-WBTC-SolvVaultGuardianForSafe13"];

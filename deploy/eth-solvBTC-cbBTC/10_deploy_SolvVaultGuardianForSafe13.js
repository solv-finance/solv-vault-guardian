module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";
  const safeAccount = "0xAd713bd85E8bff9CE85Ca03a8A930e4a38f6893D";
  const safeGovernor = deployer; //will transfer to safeGovernor after deployed
  const allowSetGuard = true;

  const deployName = "eth-solvBTC-cbBTC-SolvVaultGuardianForSafe13";
  const guardian = await deploy(deployName, {
    from: deployer,
    contract: "SolvVaultGuardianForSafe13",
    args: [safeAccount, safeMultiSendContract, safeGovernor, allowSetGuard],
    log: true
  });

  console.log(`${deployName} deployed at ${guardian.address}`);
};

module.exports.tags = ["eth-solvBTC-cbBTC-SolvVaultGuardianForSafe13"];

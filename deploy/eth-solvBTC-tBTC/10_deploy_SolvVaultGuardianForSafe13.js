module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";
  const safeAccount = "0xb4378d4e3528C12C83821b21c99b43336A543613";
  const safeGovernor = deployer; // will transfer to safeGovernor after deployed
  const allowSetGuard = true;

  const deployName = "eth-solvBTC-tBTC-SolvVaultGuardianForSafe13";
  const guardian = await deploy(deployName, {
    from: deployer,
    contract: "SolvVaultGuardianForSafe13",
    args: [safeAccount, safeMultiSendContract, safeGovernor, allowSetGuard],
    log: true
  });

  console.log(`${deployName} deployed at ${guardian.address}`);
};

module.exports.tags = ["eth-solvBTC-tBTC-SolvVaultGuardianForSafe13"];

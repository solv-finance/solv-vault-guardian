module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";
  const safeAccount = "0x9Bc8EF6bb09e3D0F3F3a6CD02D2B9dC3115C7c5C";
  const safeGovernor = deployer; //will transfer to safeGovernor after deployed
  const allowSetGuard = true;

  const deployName = "eth-solvBTC-WBTC-SolvVaultGuardianForSafe13";
  const guardian = await deploy(deployName, {
    from: deployer,
    contract: "SolvVaultGuardianForSafe13",
    args: [safeAccount, safeMultiSendContract, safeGovernor, allowSetGuard],
    log: true
  });

  console.log(`${deployName} deployed at ${guardian.address}`);
};

module.exports.tags = ["eth-solvBTC-WBTC-SolvVaultGuardianForSafe13"];

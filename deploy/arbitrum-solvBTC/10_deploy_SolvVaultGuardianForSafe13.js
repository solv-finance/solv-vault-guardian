module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";
  const safeAccount = "0x032470abbb896b1255299d5165c1a5e9ef26bcd2";
  const safeGovernor = deployer; //will transfer to safeGovernor after deployed
  const allowSetGuard = false;

  const deployName = "arb-solvBTC-SolvVaultGuardianForSafe13";
  const guardian = await deploy(deployName, {
    from: deployer,
    contract: "SolvVaultGuardianForSafe13",
    args: [safeAccount, safeMultiSendContract, safeGovernor, allowSetGuard],
    log: true
  });

  console.log(`${deployName} deployed at ${guardian.address}`);
};

module.exports.tags = ["arb-solvBTC-SolvVaultGuardianForSafe13"];

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";
  const safeAccount = "0x37059EBB0b92FCd04caEe6EB84542148109b8a30";
  const safeGovernor = deployer; //will transfer to safeGovernor after deployed
  const allowSetGuard = true;

  const deployName = "bsc-solvBTC-Ethena-C-SolvVaultGuardianForSafe13";
  const guardian = await deploy(deployName, {
    from: deployer,
    contract: "SolvVaultGuardianForSafe13",
    args: [safeAccount, safeMultiSendContract, safeGovernor, allowSetGuard],
    log: true,
  });

  console.log(`${deployName} deployed at ${guardian.address}`);
};

module.exports.tags = ["bsc-solvBTC-Ethena-C-SolvVaultGuardianForSafe13"];

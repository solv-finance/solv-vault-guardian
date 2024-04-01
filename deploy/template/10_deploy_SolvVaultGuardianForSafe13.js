module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const safeMultiSendContract = "";
  const safeAccount = "";
  const safeGovernor = deployer; //will transfer to safeGovernor after deployed
  const allowSetGuard = true;

  const deployName = "chain-name-SolvVaultGuardianForSafe13";
  const guardian = await deploy(deployName, {
    from: deployer,
    contract: "SolvVaultGuardianForSafe13",
    args: [safeAccount, safeMultiSendContract, safeGovernor, allowSetGuard],
    log: true,
  });

  console.log(`${deployName} deployed at ${guardian.address}`);
};

module.exports.tags = ["chain-name-SolvVaultGuardianForSafe13"];

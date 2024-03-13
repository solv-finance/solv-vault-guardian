module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";
  const safeAccount = "0xa743ccf2556c5660a826a9a1ac35c2eb5ef71114";
  const safeGovernor = deployer; //will transfer to safeGovernor after deployed
  const allowSetGuard = true;

  const deployName = "arb-pilot-SolvVaultGuardianForSafe13";
  const guardian = await deploy(deployName, {
    from: deployer,
    contract: "SolvVaultGuardianForSafe13",
    args: [
      safeAccount, safeMultiSendContract, safeGovernor, allowSetGuard
    ],
    log: true,
  });

  console.log(`${deployName} deployed at ${guardian.address}`);
};

module.exports.tags = ["arb-pilot-SolvVaultGuardianForSafe13"];

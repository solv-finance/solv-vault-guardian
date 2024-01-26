module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";
  const safeAccount = "0x1Df764Dae64019414759a237A6725431FF73aa8f";
  const safeGovernor = deployer; // will transfer to safeGovernor after deployed
  const allowSetGuard = true;

  let deployName = "mantle-WETH-A-SolvVaultGuardianForSafe13";

  const guardian = await deploy(deployName, {
    from: deployer,
    contract: "SolvVaultGuardianForSafe13",
    args: [safeAccount, safeMultiSendContract, safeGovernor, allowSetGuard],
    log: true,
  });

  console.log(`${deployName} deployed at ${guardian.address}`);
};

module.exports.tags = ["mantle-WETH-A-SolvVaultGuardianForSafe13"];

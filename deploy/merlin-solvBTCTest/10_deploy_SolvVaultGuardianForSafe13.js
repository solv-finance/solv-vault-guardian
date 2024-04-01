module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";
  const safeAccount = "0x3b29cf7dafa8a76dc26fb8276f70e33e0218f253";
  const safeGovernor = deployer; //will transfer to safeGovernor after deployed
  const allowSetGuard = true;

  const deployName = "merlin-solvBTCTest-SolvVaultGuardianForSafe13";
  const guardian = await deploy(deployName, {
    from: deployer,
    contract: "SolvVaultGuardianForSafe13",
    args: [safeAccount, safeMultiSendContract, safeGovernor, allowSetGuard],
    log: true,
    gasPrice: 0.05e9,
  });

  console.log(`${deployName} deployed at ${guardian.address}`);
};

module.exports.tags = ["merlin-solvBTCTest-SolvVaultGuardianForSafe13"];

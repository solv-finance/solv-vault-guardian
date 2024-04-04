module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";
  const safeAccount = "0x6a57a8d6c4fe64b1fd6e8c3e07b0591d22b7ce7f";
  const safeGovernor = deployer; //will transfer to safeGovernor after deployed
  const allowSetGuard = false;

  const deployName = "merlin-solvBTC-SolvVaultGuardianForSafe13";
  const guardian = await deploy(deployName, {
    from: deployer,
    contract: "SolvVaultGuardianForSafe13",
    args: [safeAccount, safeMultiSendContract, safeGovernor, allowSetGuard],
    log: true,
    gasPrice: 0.05e9
  });

  console.log(`${deployName} deployed at ${guardian.address}`);
};

module.exports.tags = ["merlin-solvBTC-SolvVaultGuardianForSafe13"];

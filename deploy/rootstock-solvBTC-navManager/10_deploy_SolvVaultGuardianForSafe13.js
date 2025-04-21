module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";
  const safeAccount = "0x538db8bdd683b941d6cee61d9a7a128d53c32522";
  const safeGovernor = deployer; // will transfer to safeGovernor after deployed
  const allowSetGuard = true;

  const deployName = "rootstock-solvBTC-NavManagerGuardianForSafe13";
  const guardian = await deploy(deployName, {
    from: deployer,
    contract: "SolvVaultGuardianForSafe13",
    args: [safeAccount, safeMultiSendContract, safeGovernor, allowSetGuard],
    skipIfAlreadyDeployed: true,
    log: true
  });
  console.log(`${deployName} deployed at ${guardian.address}`);

  await hre.run("verify:verify", {
    address: guardian.address,
    constructorArguments: [safeAccount, safeMultiSendContract, safeGovernor, allowSetGuard]
  });
};

module.exports.tags = ["rootstock-solvBTC-NavManagerGuardianForSafe13"];

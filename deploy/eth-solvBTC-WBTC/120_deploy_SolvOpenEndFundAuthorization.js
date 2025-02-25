module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const guardianConfig = require('./00_export_VaultGuardianConfig');

  const caller = (await deployments.get("eth-solvBTC-WBTC-SolvVaultGuardianForSafe13")).address;

  const share = guardianConfig.ShareSFT;
  const redemption = guardianConfig.RedemptionSFT;
  const repayablePoolIds = [
    guardianConfig.poolId,
  ];

  const deployName = "eth-solvBTC-WBTC-SolvOpenEndFundAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "SolvOpenEndFundAuthorization",
    args: [ caller, share, redemption, repayablePoolIds ],
    skipIfAlreadyDeployed: true,
    log: true
  });

  const AuthorizationFactory = await ethers.getContractFactory("SolvOpenEndFundAuthorization");
  const authorizationInstance = AuthorizationFactory.attach(authorization.address);
  const currentGovernor = await authorizationInstance.governor();
  const pendingGovernor = await authorizationInstance.pendingGovernor();
  if (currentGovernor != guardianConfig.GuardianGovernor && pendingGovernor != guardianConfig.GuardianGovernor) {
    const transferGovernanceTx = await authorizationInstance.transferGovernance(guardianConfig.GuardianGovernor);
    await transferGovernanceTx.wait();
    console.log(`Governance transferred to ${guardianConfig.GuardianGovernor}`);
  }
};

module.exports.tags = ["eth-solvBTC-WBTC-SolvOpenEndFundAuthorization"];

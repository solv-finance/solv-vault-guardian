module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("eth-solvBTC-WBTC-SolvVaultGuardianForSafe13")).address;

  const openEndFundShare = "0x7d6C3860B71CF82e2e1E8d5D104CF77f5B84f93a";
  const openEndFundRedemption = "0xD3BA838B3e32654aD2Ad1741d2483d807c49e6F9";
  const repayablePoolIds = [
    "0x716db7dc196abe78d5349c7166896f674ab978af26ada3e5b3ea74c5a1b48307",
  ];

  const deployName = "eth-solvBTC-WBTC-SolvOpenEndFundAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "SolvOpenEndFundAuthorization",
    args: [caller, openEndFundShare, openEndFundRedemption, repayablePoolIds],
    log: true
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["eth-solvBTC-WBTC-SolvOpenEndFundAuthorization"];

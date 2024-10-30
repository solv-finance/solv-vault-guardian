module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("eth-solvBTC-FBTC-SolvVaultGuardianForSafe13")).address;

  const openEndFundShare = "0x7d6C3860B71CF82e2e1E8d5D104CF77f5B84f93a";
  const openEndFundRedemption = "0xD3BA838B3e32654aD2Ad1741d2483d807c49e6F9";
  const repayablePoolIds = [
    "0x2dc130e46b5958208155546bd4049d5b3319798063a8c4180b4b2b82f3ebdc3d",
  ];

  const deployName = "eth-solvBTC-FBTC-SolvOpenEndFundAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "SolvOpenEndFundAuthorization",
    args: [caller, openEndFundShare, openEndFundRedemption, repayablePoolIds],
    log: true
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["eth-solvBTC-FBTC-SolvOpenEndFundAuthorization"];

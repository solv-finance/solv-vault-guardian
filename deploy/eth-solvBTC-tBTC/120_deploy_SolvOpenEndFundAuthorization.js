module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("eth-solvBTC-tBTC-SolvVaultGuardianForSafe13")).address;

  const openEndFundShare = "0x7d6C3860B71CF82e2e1E8d5D104CF77f5B84f93a";
  const openEndFundRedemption = "0xD3BA838B3e32654aD2Ad1741d2483d807c49e6F9";
  const repayablePoolIds = [
    "0x23299b545056e9846725f89513e5d7f65a5034ab36515287ff8a27e860b1be75",
  ];

  const deployName = "eth-solvBTC-tBTC-SolvOpenEndFundAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "SolvOpenEndFundAuthorization",
    args: [caller, openEndFundShare, openEndFundRedemption, repayablePoolIds],
    log: true
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["eth-solvBTC-tBTC-SolvOpenEndFundAuthorization"];

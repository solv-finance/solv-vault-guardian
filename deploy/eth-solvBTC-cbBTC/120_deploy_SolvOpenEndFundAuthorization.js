module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("eth-solvBTC-cbBTC-SolvVaultGuardianForSafe13")).address;

  const openEndFundShare = "0x7d6C3860B71CF82e2e1E8d5D104CF77f5B84f93a";
  const openEndFundRedemption = "0xD3BA838B3e32654aD2Ad1741d2483d807c49e6F9";
  const repayablePoolIds = [
    "0xdc0937dd33c4af08a08724da23bc45b33b43fbb23f365e7b50a536ce45f447ef",
  ];

  const deployName = "eth-solvBTC-cbBTC-SolvOpenEndFundAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "SolvOpenEndFundAuthorization",
    args: [caller, openEndFundShare, openEndFundRedemption, repayablePoolIds],
    log: true
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["eth-solvBTC-cbBTC-SolvOpenEndFundAuthorization"];

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (
    await deployments.get("chain-name-SolvVaultGuardianForSafe13")
  ).address;

  const openEndFundShare = "";
  const openEndFundRedemption = "";
  const repayablePoolIds = [""];

  const deployName = "chain-name-SolvOpenEndFundAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "SolvOpenEndFundAuthorization",
    args: [caller, openEndFundShare, openEndFundRedemption, repayablePoolIds],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["chain-name-SolvOpenEndFundAuthorization"];

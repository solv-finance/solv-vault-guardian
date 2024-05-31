module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (
    await deployments.get("bsc-solvBTC-Ethena-C-SolvVaultGuardianForSafe13")
  ).address;

  const openEndFundShare = "0xb816018e5d421e8b809a4dc01af179d86056ebdf";
  const openEndFundRedemption = "0xe16cec2f385ea7a382772334a44506a865f98562";
  const repayablePoolIds = [
    "0xfb479486b8b4aefd5166608f8c17dc7d8cf3a44dd37c25879645dfc130e13f44",
  ];

  const deployName = "bsc-solvBTC-Ethena-C-SolvOpenEndFundAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "SolvOpenEndFundAuthorization",
    args: [caller, openEndFundShare, openEndFundRedemption, repayablePoolIds],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["bsc-solvBTC-Ethena-C-SolvOpenEndFundAuthorization"];

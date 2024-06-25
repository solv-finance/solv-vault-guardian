module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (
    await deployments.get("bsc-solvBTC-Ethena-SolvVaultGuardianForSafe13")
  ).address;

  const openEndFundShare = "0xb816018e5d421e8b809a4dc01af179d86056ebdf";
  const openEndFundRedemption = "0xe16cec2f385ea7a382772334a44506a865f98562";
  const repayablePoolIds = [
    "0x4d4a6c1ec2386c5149c520a3c278dec0044bdac5798cfbb63ce224227b9899c5",
  ];

  const deployName = "bsc-solvBTC-Ethena-SolvOpenEndFundAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "SolvOpenEndFundAuthorization",
    args: [caller, openEndFundShare, openEndFundRedemption, repayablePoolIds],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["bsc-solvBTC-Ethena-SolvOpenEndFundAuthorization"];

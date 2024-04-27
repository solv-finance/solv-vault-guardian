module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("arb-solvBTC-SolvVaultGuardianForSafe13")).address;

  const openEndFundShare = "0xD20078BD38AbC1378cB0a3F6F0B359c4d8a7b90E";
  const openEndFundRedemption = "0x5d931F572df1cd730F1ADf3F9Eb5B218D2cE641f";
  const repayablePoolIds = [
    "0x488def4a346b409d5d57985a160cd216d29d4f555e1b716df4e04e2374d2d9f6",
  ];

  const deployName = "arb-solvBTC-SolvOpenEndFundAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "SolvOpenEndFundAuthorization",
    args: [caller, openEndFundShare, openEndFundRedemption, repayablePoolIds],
    log: true
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["arb-solvBTC-SolvOpenEndFundAuthorization"];

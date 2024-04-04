module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("bsc-solvBTC-SolvVaultGuardianForSafe13")).address;

  const openEndFundShare = "0x744697899058b32d84506AD05DC1f3266603aB8A";
  const openEndFundRedemption = "0xAa295fF24c1130A4ceb07842860a8fD7CB9de9Cd";
  const repayablePoolIds = [
    "0xafb1107b43875eb79f72e3e896933d4f96707451c3d5c32741e8e05410b321d8",
  ];

  const deployName = "bsc-solvBTC-SolvOpenEndFundAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "SolvOpenEndFundAuthorization",
    args: [caller, openEndFundShare, openEndFundRedemption, repayablePoolIds],
    log: true
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["bsc-solvBTC-SolvOpenEndFundAuthorization"];

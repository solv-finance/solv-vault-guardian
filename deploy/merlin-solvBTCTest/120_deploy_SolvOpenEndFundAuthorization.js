module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (
    await deployments.get("merlin-solvBTCTest-SolvVaultGuardianForSafe13")
  ).address;

  const openEndFundShare = "0x1f4d23513c3ef0d63b97bbd2ce7c845ebb1cf1ce";
  const openEndFundRedemption = "0x9d7795c2bd2ef6098c74cb0865691cbf6aa40887";
  const repayablePoolIds = [
    "0x32228ab607d64bb5bfc0cd9720f05b0e6c7e4a0801a25e6c2b7f03d5d01e8219",
  ];

  const deployName = "merlin-solvBTC-SolvOpenEndFundAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "SolvOpenEndFundAuthorization",
    args: [caller, openEndFundShare, openEndFundRedemption, repayablePoolIds],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["merlin-solvBTCTest-SolvOpenEndFundAuthorization"];

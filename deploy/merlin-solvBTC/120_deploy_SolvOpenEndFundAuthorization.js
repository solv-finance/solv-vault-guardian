module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("merlin-solvBTC-SolvVaultGuardianForSafe13")).address;

  const openEndFundShare = "0x1f4d23513c3ef0d63b97bbd2ce7c845ebb1cf1ce";
  const openEndFundRedemption = "0x9d7795c2bd2ef6098c74cb0865691cbf6aa40887";
  const repayablePoolIds = [
    "0xdb76947333de76435723149d54aefc7c0eeea3c2ca8b763b315f4298aef33c37",
  ];

  const deployName = "merlin-solvBTC-SolvOpenEndFundAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "SolvOpenEndFundAuthorization",
    args: [caller, openEndFundShare, openEndFundRedemption, repayablePoolIds],
    log: true,
    gasPrice: 0.05e9,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["merlin-solvBTC-SolvOpenEndFundAuthorization"];

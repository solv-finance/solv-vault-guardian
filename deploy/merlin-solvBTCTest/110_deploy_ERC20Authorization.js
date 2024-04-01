module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (
    await deployments.get("merlin-solvBTCTest-SolvVaultGuardianForSafe13")
  ).address;

  const spenders = [
    [
      "0xB880fd278198bd590252621d4CD071b1842E9Bcd", // MBTC
      [
        "0x1f4d23513c3ef0d63b97bbd2ce7c845ebb1cf1ce", // OpenEndFundShare
        "0x9d7795c2bd2ef6098c74cb0865691cbf6aa40887", // OpenEndFundRedemption
      ],
    ],
  ];

  //no transfer receiver
  const receivers = [];

  const deployName = "merlin-solvBTCTest-ERC20Authorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "ERC20Authorization",
    args: [caller, spenders, receivers],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["merlin-solvBTCTest-ERC20Authorization"];

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("bsc-solvBTC-SolvVaultGuardianForSafe13")).address;

  const spenders = [
    [
      "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // BTCB
      [
        "0x744697899058b32d84506AD05DC1f3266603aB8A", // OpenEndFundShare
        "0xAa295fF24c1130A4ceb07842860a8fD7CB9de9Cd", // OpenEndFundRedemption
      ],
    ],
  ];

  //no transfer receiver
  const receivers = [];

  const deployName = "bsc-solvBTC-ERC20Authorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "ERC20Authorization",
    args: [caller, spenders, receivers],
    log: true
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["bsc-solvBTC-ERC20Authorization"];

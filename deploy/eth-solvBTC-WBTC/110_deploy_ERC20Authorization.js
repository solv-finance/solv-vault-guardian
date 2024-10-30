module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("eth-solvBTC-WBTC-SolvVaultGuardianForSafe13")).address;

  const spenders = [
    [
      "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", // WBTC
      [
        "0x7d6C3860B71CF82e2e1E8d5D104CF77f5B84f93a", // OpenEndFundShare
        "0xD3BA838B3e32654aD2Ad1741d2483d807c49e6F9", // OpenEndFundRedemption
      ],
    ],
  ];

  const receivers = [];

  const deployName = "eth-solvBTC-WBTC-ERC20Authorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "ERC20Authorization",
    args: [caller, spenders, receivers],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["eth-solvBTC-WBTC-ERC20Authorization"];

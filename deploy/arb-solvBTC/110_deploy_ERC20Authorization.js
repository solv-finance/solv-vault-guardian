module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("arb-solvBTC-SolvVaultGuardianForSafe13")).address;

  const spenders = [
    [
      "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f", // WBTC
      [
        "0xD20078BD38AbC1378cB0a3F6F0B359c4d8a7b90E", // OpenEndFundShare
        "0x5d931F572df1cd730F1ADf3F9Eb5B218D2cE641f", // OpenEndFundRedemption
        "0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8", // OpenEndFundMarket
      ],
    ],
  ];

  //no transfer receiver
  const receivers = [];

  const deployName = "arb-solvBTC-ERC20Authorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "ERC20Authorization",
    args: [caller, spenders, receivers],
    log: true
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["arb-solvBTC-ERC20Authorization"];

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("arb-solvBTC-SolvVaultGuardianForSafe13")).address;
  const safeAccount = "0x032470abbb896b1255299d5165c1a5e9ef26bcd2";

  const openEndFundRedemption = "0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c";

  const spenders = [
    [
      "0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c", // OpenEndFundRedemption
      [
        "0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8", // OpenEndFundMarket
      ]
    ]
  ];

  const deployName = "arb-solvBTC-SolvOpenEndFundRedemptionAuthorization";
  const authorization = await deploy(
    deployName, 
    {
      from: deployer,
      contract: "SolvOpenEndFundSftAuthorization",
      args: [ caller, safeAccount, openEndFundRedemption, spenders ],
      log: true
    }
  );

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["arb-solvBTC-SolvOpenEndFundRedemptionAuthorization"];

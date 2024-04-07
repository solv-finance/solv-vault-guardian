module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("arb-solvBTC-SolvVaultGuardianForSafe13")).address;
  const safeAccount = "0x032470abbb896b1255299d5165c1a5e9ef26bcd2";

  const openEndFundShare = "0x22799DAA45209338B7f938edf251bdfD1E6dCB32";

  const spenders = [
    [
      "0x22799DAA45209338B7f938edf251bdfD1E6dCB32", // OpenEndFundShare
      [
        "0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8", // OpenEndFundMarket
      ]
    ]
  ];

  const deployName = "arb-solvBTC-SolvOpenEndFundShareAuthorization";
  const authorization = await deploy(
    deployName, 
    {
      from: deployer,
      contract: "SolvOpenEndFundSftAuthorization",
      args: [ caller, safeAccount, openEndFundShare, spenders ],
      log: true
    }
  );

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["arb-solvBTC-SolvOpenEndFundShareAuthorization"];

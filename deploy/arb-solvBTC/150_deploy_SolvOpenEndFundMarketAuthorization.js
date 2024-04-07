module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("arb-solvBTC-SolvVaultGuardianForSafe13")).address;
  const safeAccount = "0x032470abbb896b1255299d5165c1a5e9ef26bcd2";
  const openFundMarket = "0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8";
  
  const poolIdWhitelist = [
    "0x3b2232fb5309e89e5ee6e2ca6066bcc28ee365045e9a565040bf8c846b87477e",  // GMX V2 WBTC - A
  ];
  
  const deployName = "arb-solvBTC-SolvOpenEndFundMarketAuthorization";
  const authorization = await deploy(
    deployName, 
    {
      from: deployer,
      contract: "SolvMasterFundAuthorization",
      args: [
        caller, 
        safeAccount, 
        openFundMarket, 
        poolIdWhitelist,
      ],
      log: true,
    }
  );

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["arb-solvBTC-SolvOpenEndFundMarketAuthorization"];

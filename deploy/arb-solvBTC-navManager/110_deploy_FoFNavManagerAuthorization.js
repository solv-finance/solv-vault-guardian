module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("arb-solvBTC-NavManagerGuardianForSafe13")).address;

  const openFundMarket = "0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8";
  const authorizedPoolIds = [
    "0x488def4a346b409d5d57985a160cd216d29d4f555e1b716df4e04e2374d2d9f6",
  ];

  const deployName = "arb-solvBTC-FoFNavManagerAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "FoFNavManagerAuthorization",
    args: [caller, openFundMarket, authorizedPoolIds],
    skipIfAlreadyDeployed: true,
    log: true
  });
  console.log(`${deployName} deployed at ${authorization.address}`);

  await hre.run("verify:verify", {
    address: authorization.address,
    constructorArguments: [caller, openFundMarket, authorizedPoolIds],
  })
};

module.exports.tags = ["arb-solvBTC-FoFNavManagerAuthorization"];

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("soneium-solvBTC-NavManagerGuardianForSafe13")).address;

  const openFundMarket = "0xB381fD599649322b143978f8a1fCa0cB41a4Ab5a";
  const authorizedPoolIds = [
    "0x24c57463cb22eb61e11661ac83df852fa4cd28ac4760dcc465cdfebebef8cd6d",
  ];

  const deployName = "soneium-solvBTC-FoFNavManagerAuthorization";
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

module.exports.tags = ["soneium-solvBTC-FoFNavManagerAuthorization"];

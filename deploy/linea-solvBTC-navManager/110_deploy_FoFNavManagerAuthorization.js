module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("linea-solvBTC-NavManagerGuardianForSafe13")).address;

  const openFundMarket = "0xf5a247157656678398B08d3eFa1673358C611A3f";
  const authorizedPoolIds = [
    "0xc36666b59fc86c86169d0aea459635cf9f99f6c9b18b8152ca2ccc6de3362c93",
  ];

  const deployName = "linea-solvBTC-FoFNavManagerAuthorization";
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

module.exports.tags = ["linea-solvBTC-FoFNavManagerAuthorization"];

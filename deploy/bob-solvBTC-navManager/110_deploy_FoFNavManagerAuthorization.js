module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("bob-solvBTC-NavManagerGuardianForSafe13")).address;

  const openFundMarket = "0xf5a247157656678398B08d3eFa1673358C611A3f";
  const authorizedPoolIds = [
    "0x5664520240a46b4b3e9655c20cc3f9e08496a9b746a478e476ae3e04d6c8fc31",
  ];

  const deployName = "bob-solvBTC-FoFNavManagerAuthorization";
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

module.exports.tags = ["bob-solvBTC-FoFNavManagerAuthorization"];

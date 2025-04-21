module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("base-solvBTC-NavManagerGuardianForSafe13")).address;

  const openFundMarket = "0xf5a247157656678398B08d3eFa1673358C611A3f";
  const authorizedPoolIds = [
    "0x0d85d41382f6f2effeaa41a46855870ec8b1577c6c59cf16d72856a22988e3f5",
    "0x1706a4881586917b18c2274dfdbcdffe48ee22e18c99090dcee7dd38464526b4"
  ];

  const deployName = "base-solvBTC-FoFNavManagerAuthorization";
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

module.exports.tags = ["base-solvBTC-FoFNavManagerAuthorization"];

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("avax-solvBTC-NavManagerGuardianForSafe13")).address;

  const openFundMarket = "0x59Cf3db95bdF5C545877871c3863c9DBe6b0b7cf";
  const authorizedPoolIds = [
    "0xf5ae38da3319d22b4628e635f6fa60bf966de13c5334b6845eba764d6321e16b",
  ];

  const deployName = "avax-solvBTC-FoFNavManagerAuthorization";
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

module.exports.tags = ["avax-solvBTC-FoFNavManagerAuthorization"];

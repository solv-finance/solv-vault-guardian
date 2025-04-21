module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("rootstock-solvBTC-NavManagerGuardianForSafe13")).address;

  const openFundMarket = "0x6c8dA184B019E6C4Baa710113c0d9DE68A693B1f";
  const authorizedPoolIds = [
    "0xf565aa1c019284a525d3157a65249ab8eae5792d52607b5469304b883afe1298",
  ];

  const deployName = "rootstock-solvBTC-FoFNavManagerAuthorization";
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

module.exports.tags = ["rootstock-solvBTC-FoFNavManagerAuthorization"];

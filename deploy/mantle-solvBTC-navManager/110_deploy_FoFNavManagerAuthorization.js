module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("mantle-solvBTC-NavManagerGuardianForSafe13")).address;

  const openFundMarket = "0x1210371F2E26a74827F250afDfdbE3091304a3b7";
  const authorizedPoolIds = [
    "0x5fb3c44123fbc670235d925a21f34b75bc33a7d48bee64341dc75aadda58988d",
  ];

  const deployName = "mantle-solvBTC-FoFNavManagerAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "FoFNavManagerAuthorization",
    args: [caller, openFundMarket, authorizedPoolIds],
    log: true
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["mantle-solvBTC-FoFNavManagerAuthorization"];

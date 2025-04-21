module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("eth-solvBTC-NavManagerGuardianForSafe13")).address;

  const openFundMarket = "0x57bB6a8563a8e8478391C79F3F433C6BA077c567";
  const authorizedPoolIds = [
    "0x2dc130e46b5958208155546bd4049d5b3319798063a8c4180b4b2b82f3ebdc3d",
    "0x716db7dc196abe78d5349c7166896f674ab978af26ada3e5b3ea74c5a1b48307",
    "0xdc0937dd33c4af08a08724da23bc45b33b43fbb23f365e7b50a536ce45f447ef",
    "0x23299b545056e9846725f89513e5d7f65a5034ab36515287ff8a27e860b1be75",
  ];

  const deployName = "eth-solvBTC-FoFNavManagerAuthorization";
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

module.exports.tags = ["eth-solvBTC-FoFNavManagerAuthorization"];

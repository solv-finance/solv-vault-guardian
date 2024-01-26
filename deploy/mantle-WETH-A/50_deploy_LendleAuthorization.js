module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";
  const caller = (await deployments.get("mantle-WETH-A-SolvVaultGuardianForSafe13")).address;
  const safeAccount = "0x1Df764Dae64019414759a237A6725431FF73aa8f";

  const lendlePool = "0xCFa5aE7c2CE8Fadc6426C1ff872cA45378Fb7cF3";
  const assetWhitelist = [
    "0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111", // WETH
    "0xcDA86A272531e8640cD7F1a92c01839911B90bb0", // mETH
  ];

  let deployName = "mantle-WETH-A-LendleAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "LendleAuthorization",
    args: [ safeMultiSendContract, caller, safeAccount, lendlePool, assetWhitelist ],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["mantle-WETH-A-LendleAuthorization"];

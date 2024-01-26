module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("mantle-WETH-A-SolvVaultGuardianForSafe13")).address;
  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";
  const openEndFundShare = "0x788dC3af7B62708b752d483a6E30d1Cf23c3EaAe";
  const openEndFundRedemption = "0x9b8a1B5d2f1BcC95d1CEab97FA9e063464418925";
  const repayablePoolIds = [
    "0x8aeda782c271f9d79110d12410640a393c5ad1fdd6f3812208c0052637eea338",
  ];

  let deployName = "mantle-WETH-A-SolvOpenEndFundAuthorization";

  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "SolvOpenEndFundAuthorization",
    args: [
      safeMultiSendContract,
      caller,
      openEndFundShare,
      openEndFundRedemption,
      repayablePoolIds,
    ],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["mantle-WETH-A-SolvOpenEndFundAuthorization"];

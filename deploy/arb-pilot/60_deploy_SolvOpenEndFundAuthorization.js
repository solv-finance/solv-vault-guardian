module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("arb-pilot-SolvVaultGuardianForSafe13"))
    .address;
  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";
  const openEndFundShare = "0x22799DAA45209338B7f938edf251bdfD1E6dCB32";
  const openEndFundRedemption = "0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c";
  const repayablePoolIds = [
    "0x375ebcd78e8b3571c0f6482bdaae602672e73e145e92ca40f9b8f1537236bf2e",
  ];

  let deployName = "arb-pilot-SolvOpenEndFundAuthorization";

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

module.exports.tags = ["arb-pilot-SolvOpenEndFundAuthorization"];

module.exports = async ({ getNamedAccounts, deployments }) => {

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get('SolvVaultGuardianForSafe13')).address;
  
  const openEndFundShare = "0x22799DAA45209338B7f938edf251bdfD1E6dCB32";
  const openEndFundRedemption = "0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c";
  const repayablePoolIds = [
    "0x375ebcd78e8b3571c0f6482bdaae602672e73e145e92ca40f9b8f1537236bf2e",
  ];

  await deploy('SolvOpenEndFundAuthorization', {
    from: deployer,
    contract: "SolvOpenEndFundAuthorization",
    args: [
      caller,
      openEndFundShare,
      openEndFundRedemption,
      repayablePoolIds,
    ],
    log: true,
  });
};

module.exports.tags = ['SolvOpenEndFundAuthorization'];
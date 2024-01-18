module.exports = async ({ getNamedAccounts, deployments }) => {

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get('SolvVaultGuardianForSafe13')).address;
  const safeMultiSendContract = '0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761';
  const openEndFundMarket = '0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8';
  const openEndFundShare = '0x22799DAA45209338B7f938edf251bdfD1E6dCB32';
  const openEndFundRedemption = '0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c';
  const repayablePoolIds = [
    '0x0ef01fb59f931e3a3629255b04ce29f6cd428f674944789288a1264a79c7c931'
  ];

  await deploy('SolvOpenEndFundAuthorization', {
    from: deployer,
    args: [ 
      safeMultiSendContract,
      caller,
      openEndFundMarket,
      openEndFundShare,
      openEndFundRedemption,
      repayablePoolIds
    ],
    log: true,
  });
};

module.exports.tags = ['SolvOpenEndFundAuthorization'];
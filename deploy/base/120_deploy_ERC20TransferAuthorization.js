module.exports = async ({ getNamedAccounts, deployments }) => {

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get('SolvVaultGuardianForSafe13')).address;
  const safeMultiSendContract = '0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761';

  const tokenReceivers = [
    [
      '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9',   // token
      [
        '0x22799DAA45209338B7f938edf251bdfD1E6dCB32', // receivers
        '0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c',
      ]
    ],
    [
      '0xaf88d065e77c8cC2239327C5EDb3A432268e5831',   // token
      [
        '0x22799DAA45209338B7f938edf251bdfD1E6dCB32', // receivers
        '0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c',
      ]
    ]
  ];

  await deploy('ERC20TransferAuthorization', {
    from: deployer,
    args: [ 
      safeMultiSendContract,
      caller,
      tokenReceivers
    ],
    log: true,
  });
};

module.exports.tags = ['ERC20TransferAuthorization'];
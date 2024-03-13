module.exports = async ({ getNamedAccounts, deployments }) => {

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get('SolvVaultGuardianForSafe13')).address;

  const spenders = [];

  const receivers = [
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

  await deploy('ERC20Authorization', {
    from: deployer,
    args: [ caller, spenders, receivers ],
    log: true,
  });
};

module.exports.tags = ['ERC20Authorization'];
module.exports = async ({ getNamedAccounts, deployments }) => {

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get('SolvVaultGuardianForSafe13')).address;
  const safeAccount = '0x9B1cf397C9ECdD70F76d0B6f51A2582EeEED2eb7';

  const exchangeRouter = '0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8';
  const depositVault = '0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55';
  const withdrawalVault = '0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55';

  const gmTokens = [
    '0x47c031236e19d024b42f8AE6780E44A573170703', // GM: BTC-USDC
    '0x70d95587d40A2caf56bd97485aB3Eec10Bee6336', // GM: ETH-USDC
    '0xC25cEf6061Cf5dE5eb761b50E4743c1F5D7E5407', // GM: ARB-USDC
  ];

  const gmPairs = [
    [ 
      '0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f', // WBTC
      '0xaf88d065e77c8cC2239327C5EDb3A432268e5831', // USDC
    ],
    [
      '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1', // WETH
      '0xaf88d065e77c8cC2239327C5EDb3A432268e5831', // USDC
    ],
    [
      '0x912CE59144191C1204E64559FE8253a0e49E6548', // ARB
      '0xaf88d065e77c8cC2239327C5EDb3A432268e5831', // USDC
    ],
  ];
  
  await deploy('GMXV2Authorization', {
    from: deployer,
    args: [ 
      caller,
      safeAccount,
      exchangeRouter,
      depositVault,
      withdrawalVault,
      gmTokens, 
      gmPairs
    ],
    log: true,
  });
};

module.exports.tags = ['GMXV2Authorization'];
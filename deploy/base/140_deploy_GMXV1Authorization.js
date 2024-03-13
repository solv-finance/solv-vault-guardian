module.exports = async ({ getNamedAccounts, deployments }) => {

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get('SolvVaultGuardianForSafe13')).address;
  const safeAccount = '0x9B1cf397C9ECdD70F76d0B6f51A2582EeEED2eb7';

  const gmxRewardRouter = '0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1';
  const gmxRewardRouterV2 = '0xB95DB5B167D75e6d04227CfFFA61069348d271F5';

  const allowTokens = [
    '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // ETH
    '0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f', // WBTC
    '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1', // WETH
    '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9', // USDT
    '0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8', // USDC
  ];

  await deploy('GMXV1Authorization', {
    from: deployer,
    args: [ 
      caller,
      safeAccount,
      gmxRewardRouter,
      gmxRewardRouterV2,
      allowTokens
    ],
    log: true,
  });
};

module.exports.tags = ['GMXV1Authorization'];
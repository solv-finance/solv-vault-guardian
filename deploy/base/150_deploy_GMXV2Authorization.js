module.exports = async ({ getNamedAccounts, deployments }) => {

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get('SolvVaultGuardianForSafe13')).address;
  const safeMultiSendContract = '0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761';
  const safeAccount = '0x9B1cf397C9ECdD70F76d0B6f51A2582EeEED2eb7';
  const exchangeRouter = '0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8';
  const depositVault = '0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55';
  const withdrawalVault = '0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55';
  
  await deploy('GMXV2Authorization', {
    from: deployer,
    args: [ 
      safeMultiSendContract,
      caller,
      safeAccount,
      exchangeRouter,
      depositVault,
      withdrawalVault
    ],
    log: true,
  });
};

module.exports.tags = ['GMXV2Authorization'];
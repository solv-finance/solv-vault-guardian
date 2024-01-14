module.exports = async ({ getNamedAccounts, deployments }) => {

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get('SolvVaultGuardianForSafe13')).address;
  const safeMultiSendContract = '0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761';
  const safeAccount = '0x9B1cf397C9ECdD70F76d0B6f51A2582EeEED2eb7';

  await deploy('GMXV1Authorization', {
    from: deployer,
    args: [ 
      safeAccount,
      safeMultiSendContract,
      caller,
    ],
    log: true,
  });
};

module.exports.tags = ['GMXV1Authorization'];
module.exports = async ({ getNamedAccounts, deployments }) => {

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const safeMultiSendContract = '0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761';
  const safeAccount = '0x9B1cf397C9ECdD70F76d0B6f51A2582EeEED2eb7';
  const safeGovernor = '0x15f043CFC880B3e17Ffd15E6D0A4dc17A951a863';
  const allowSetGuard = true;

  await deploy('SolvVaultGuardianForSafe13', {
    from: deployer,
    args: [ 
      safeAccount, 
      safeMultiSendContract,
      safeGovernor,
      allowSetGuard
    ],
    log: true,
  });
};

module.exports.tags = ['SolvVaultGuardianForSafe13'];
module.exports = async ({ getNamedAccounts, deployments }) => {

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get('SolvVaultGuardianForSafe13')).address;
  const safeMultiSendContract = '0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761';
  const argusAccountHelper = '0x58D3a5586A8083A207A01F21B971157921744807';
  const argusFlatRoleManager = '0x80346Efdc8957843A472e5fdaD12Ea4fD340A845';
  const argusFarmingBaseAcl = '0xFd11981Da6af3142555e3c8B60d868C7D7eE1963';

  await deploy('CoboArgusAdminAuthorization', {
    from: deployer,
    args: [ 
      safeMultiSendContract,
      caller,
      argusAccountHelper,
      argusFlatRoleManager,
      argusFarmingBaseAcl
    ],
    log: true,
  });
};

module.exports.tags = ['CoboArgusAdminAuthorization'];
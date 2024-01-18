module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("arb-pilot-SolvVaultGuardianForSafe13"))
    .address;

  console.log("caller ", caller);
  const safeMultiSendContract = "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761";

  const tokenReceivers = [
    [
      "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9", // USDT
      [
        "0x24607c8ace27f42376a4faae967892a24a5a269b", // CEX Recharge Address
      ],
    ],
  ];

  let deployName = "arb-pilot-ERC20TransferAuthorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "ERC20TransferAuthorization",
    args: [safeMultiSendContract, caller, tokenReceivers],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["arb-pilot-ERC20TransferAuthorization"];

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (
    await deployments.get("eth-AA-Safe-SolvVaultGuardianForSafe13")
  ).address;

  const spenders = [];

  const receivers = [
    [
      "0xdac17f958d2ee523a2206206994597c13d831ec7", // USDT
      [
        "0xF98099decb7A4819f18c3F2C5FAa153A33740565", // receiver, Ethena Minter
      ],
    ],
    [
      "0x4c9EDD5852cd905f086C759E8383e09bff1E68B3", //USDE
      ["0x464D0cCff5E05F2aFC69561Fd849e46d96492203"], //AA
    ],
  ];

  const deployName = "eth-AA-Safe-ERC20Authorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "ERC20Authorization",
    args: [caller, spenders, receivers],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["eth-AA-Safe-ERC20Authorization"];

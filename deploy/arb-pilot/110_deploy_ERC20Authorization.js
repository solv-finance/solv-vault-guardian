module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("arb-pilot-SolvVaultGuardianForSafe13")).address;

  const spenders = [
    [
      "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9", // USDT
      [
        "0x22799DAA45209338B7f938edf251bdfD1E6dCB32", // OpenEndFundShare
        "0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c", // OpenEndFundRedemption
      ]
    ],
  ];

  const receivers = [
    [
      "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9", // USDT
      [
        "0x24607c8ace27f42376a4faae967892a24a5a269b", // CEX Recharge Address
      ],
    ],
  ];

  const deployName = "arb-pilot-ERC20Authorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "ERC20Authorization",
    args: [ caller, spenders, receivers ],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["arb-pilot-ERC20Authorization"];
